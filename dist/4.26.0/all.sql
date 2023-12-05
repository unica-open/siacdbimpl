/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--SIAC-7678 - Maurizio - INIZIO.
DROP FUNCTION if exists siac."BILR024_Allegato_7_Allegato_delibera_variaz_totali_entrate_txt"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);
DROP FUNCTION if exists siac."BILR024_Allegato_7_Allegato_delibera_variaz_totali_spese_txt"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);
DROP FUNCTION if exists siac."BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_totali_txt"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);
DROP FUNCTION if exists siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_totali_txt"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);


CREATE OR REPLACE FUNCTION siac.fnc_bilr_tracciato_400_cad (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar
)
RETURNS TABLE (
  riga_tracciato text
) AS
$body$
DECLARE

codice_ente varchar;
code_organo_provv varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona e' quella principale chiamata dall'applicazione.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    Effettua il controlla della correttezza dei parametri e, in base al 
    codice report, richiama le procedure corrette per generare i tracciati
    corretti.
    Funziona solo per i report BILR024, BILR139 e BILR146.

*/

	/*
	-- DEBUG NON TOGLIERE QUESTE RIGHE.
    -- Servono per evenutali verifiche dei parametri ricevuti.
		return QUERY 
  SELECT 	'1 ente: ' || coalesce (p_ente_prop_id::text, 'null val')
 UNION SELECT    '2 anno: ' || coalesce (p_anno::text, 'null val')
  UNION SELECT   '3 num delib: ' ||  coalesce (p_numero_delibera::text, 'null val')
  UNION SELECT  '4 anno delib: ' ||  coalesce (p_anno_delibera::text, 'null val')
  UNION SELECT '5 tipo delib: ' ||  coalesce (p_tipo_delibera::text, 'null val')
  UNION SELECT 	'6 anno comp: ' || coalesce (p_anno_competenza::text, 'null val')
  UNION SELECT 	'7 ele variaz: ' || coalesce (p_ele_variazioni::text, 'null val')
  UNION SELECT '8 organo provv: ' || coalesce (p_organo_provv::text, 'null val')
  UNION SELECT '9 code report: ' || coalesce (p_code_report::text, 'null val') 
 order by 1;
*/
	
  --Controllo dei parametri
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

if  contaParametriParz = 1 
    OR contaParametriParz = 2 
    OR (contaParametriParz = 3 and (p_organo_provv IS NULL OR
				p_organo_provv = ''))     then
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
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
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;
    
if p_organo_provv = '' Or p_organo_provv IS NULL then
	riga_tracciato:= 'ERRORE NEI PARAMETRI: Specificare l''organo che ha emesso il Provvedimento';
    return next;
    return;	
end if;

-- imposto il codice ente. 
codice_ente:='';
select ente_oil_codice
	into codice_ente
from siac_t_ente_oil a
where a.ente_proprietario_id= p_ente_prop_id
	and a.data_cancellazione IS NULL;

if codice_ente is null or codice_ente = '' then
	riga_tracciato:= 'ERRORE: non e'' stato configurato il codice dell''ente';
    return next;
    return;		
else 
	codice_ente:=LPAD(codice_ente, 7, '0');    
end if;    

	--imposto il codice relativo all'organo che ha emesso il provvedimento.
if upper(p_organo_provv) like '%GIUNTA%' then
	code_organo_provv:='G';
elsif  upper(p_organo_provv) like '%CONSIGLIO%' then
	code_organo_provv:='C';
else 
	code_organo_provv:='A'; --Assemblea.
end if;

raise notice 'code_organo_provv = %', code_organo_provv;

if p_code_report = 'BILR024' OR p_code_report = 'BILR149' then
    RETURN QUERY
        select record_t2sb20s::text rec
        from "fnc_tracciato_t2sb20s"(p_ente_prop_id, p_anno ,
                    p_numero_delibera ,  p_anno_delibera ,
                    p_tipo_delibera ,  p_anno_competenza ,
                    p_ele_variazioni, code_organo_provv,p_code_report,
                    codice_ente)
    UNION
        select record_t2sb21s::text rec
        from "fnc_tracciato_t2sb21s"(p_ente_prop_id, p_anno ,
                    p_numero_delibera ,  p_anno_delibera ,
                    p_tipo_delibera ,  p_anno_competenza ,
                    p_ele_variazioni, code_organo_provv,p_code_report,
                    codice_ente)
         order by rec;
else if p_code_report = 'BILR139' then
     RETURN QUERY
        select record_t2sb22s::text rec
        from "fnc_tracciato_t2sb22s"(p_ente_prop_id, p_anno ,
                    p_numero_delibera ,  p_anno_delibera ,
                    p_tipo_delibera ,  p_anno_competenza ,
                    p_ele_variazioni, code_organo_provv,p_code_report,
                    codice_ente);
	 else --09/07/2020: aggiunto il controllo sul codice report.
     	RETURN QUERY select 'Il REPORT '||p_code_report|| ' NON E'' GESTITO IN QUESTO FORMATO'::text;                                                         
     end if;                
end if;
                            

exception
	when syntax_error THEN
    	riga_tracciato='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	riga_tracciato='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;     
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_tracciato_t2sb20s (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar,
  p_codice_ente varchar
)
RETURNS TABLE (
  record_t2sb20s varchar
) AS
$body$
DECLARE

prefisso varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
elencoRec record;
importo_tot_stanz_entrate numeric;
importo_tot_cassa_entrate numeric;
importo_tot_residui_entrate numeric;
importo_tot_stanz_spese numeric;
importo_tot_cassa_spese numeric;
importo_tot_residui_spese numeric;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona prepara i dati del tracciato t2sb20s.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    In base al report richiama le procedure corrette.
    Funziona solo per i report BILR024 e BILR146.

*/

/* 02/07/2020 SIAC-7678.
	I totali devono essere solo i totali delle variazioni e corrispndere a quanto
    calcolato per il tracciato t2sb21s.
    Le funzioni:
    - BILR024_Allegato_7_Allegato_delibera_variaz_totali_entrate_txt
    - BILR024_Allegato_7_Allegato_delibera_variaz_totali_spese_txt 
    - BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_totali_txt
    - BILR149_Allegato_8_variazioni_eserc_gestprov_spesee_totali_txt
    che erano utilizzate per il calcolo dei totali complessivi non sono piu' usate.
*/

if p_code_report = 'BILR024' then
   return query 
          select (	--CIST
                '00001'  || 
                    --CENT codice ente 
                p_codice_ente  || 
                    --CESE codice esercizio
                p_anno_competenza  || 
                    -- NDEL Numero Delibera
                case when entrate.attoamm_id_ent is NULL then
                    LPAD(spese.attoamm_numero_spese::varchar,7,'0')
                else LPAD(entrate.attoamm_numero_ent::varchar,7,'0') end || 
                    --SORG Organo deliberante
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- CTIPREC tipo record
                '0'  || 
                    -- DDEL Data delibera
               case when entrate.attoamm_id_ent is NULL then
                    to_char(spese.data_provv_var_spese,'ddMMyyyy') 
                else to_char(entrate.data_provv_var_ent,'ddMMyyyy') end ||
                    -- ZDES descr delibera
               case when entrate.attoamm_id_ent is NULL then
                    RPAD(left(spese.attoamm_oggetto_spese,50),50,' ')
                else RPAD(left(entrate.attoamm_oggetto_ent,50),50,' ') end || 
                    -- SORGAPP  Organo approvazione
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- DDEL Data Approvazione Delibera.
               case when entrate.attoamm_id_ent is NULL then
                    to_char(spese.data_approvazione_provv_spese,'ddMMyyyy')
                else to_char(entrate.data_approvazione_provv_ent,'ddMMyyyy') end || 
                    --DDATAPP  Numero Approvazione Delibera
                LPAD('0', 7, '0') || 
                    --IENTRES Importo entrate residuo
               case when entrate.attoamm_id_ent is NULL then
                    LPAD('0',17,'0') 
                  else trim(replace(to_char(ABS(entrate.variazione_residuo_ent) ,
          				'000000000000000.00'),'.','')) end ||                  	
                    --SENTRES Segno entrate residuo  
               case when entrate.attoamm_id_ent is NULL then ' '                     
                else case when entrate.variazione_residuo_ent >=0 then '+'
                    else '-' end end || 
                    --IUSCRES Importo spese residuo
                case when spese.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0') 
                else trim(replace(to_char(ABS(spese.variazione_residuo_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCRES Segno spese residuo 
                case when spese.attoamm_id_spese IS NULL then ' '                         
                else case when spese.variazione_residuo_spese >=0 then '+'
                    else '-' end end ||                                
                    --IENTCPT Importo entrate competenza
               case when entrate.attoamm_id_ent is NULL then
                    LPAD('0',17,'0')
			   else trim(replace(to_char(ABS(entrate.variazione_stanziato_ent),
          				'000000000000000.00'),'.','')) end ||                        
                    --SENTCPT Segno entrate competenza
               case when entrate.attoamm_id_ent is NULL then ' '
                else case when entrate.variazione_stanziato_ent >=0 then '+'
                    else '-' end end ||
                    --IUSCCPT Importo spese competenza
                case when spese.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0')
                else trim(replace(to_char(ABS(spese.variazione_stanziato_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCCPT Segno spese competenza 
                case when spese.attoamm_id_spese IS NULL then ' ' 
                else case when spese.variazione_stanziato_spese >=0 then '+'
                    else '-' end end ||   
                    --IENTCAS Importo entrate cassa 
               case when entrate.attoamm_id_ent is NULL then
                    LPAD('0',17,'0')                               
                else trim(replace(to_char(ABS(entrate.variazione_cassa_ent),
          				'000000000000000.00'),'.','')) end ||
                    --SENTCAS Segno entrate cassa
               case when entrate.attoamm_id_ent is NULL then ' ' 
                else case when entrate.variazione_cassa_ent >=0 then '+'
                    else '-' end end ||
                    --IUSCCAS Importo spese cassa   
                case when spese.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0')
                else trim(replace(to_char(ABS(spese.variazione_cassa_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCCAS Segno spese cassa 
                case when spese.attoamm_id_spese IS NULL then ' '
                 else case when spese.variazione_cassa_spese >=0 then '+'
                    else '-' end end ||
                    --KEYWEB Identificativo flusso web. NON OBBLIGATORIO.    
                RPAD(' ', 30, ' ')  ||
                    --CTIPFLU Identificativo tipo flusso.
                'D' ||
                    --SSBIL Segnale stato bilancio. NON OBBLIGATORIO. 
                ' ' || 
                    --STIPINV Indicatore tipo invio. NON OBBLIGATORIO.
                ' ' || 
                    --FILLER 
                RPAD(' ', 160, ' '))::varchar 
   	        from (select attoamm_anno attoamm_anno_ent,
            attoamm_numero attoamm_numero_ent, tipo_atto tipo_atto_ent, 
            attoamm_oggetto attoamm_oggetto_ent, 
            attoamm_id attoamm_id_ent,
            data_provv_var data_provv_var_ent, 
            data_approvazione_provv data_approvazione_provv_ent,
            sum(variazione_aumento_residuo) variazione_aumento_residuo_ent,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato_ent,
            sum(variazione_aumento_cassa) variazione_aumento_cassa_ent,
            sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo_ent,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato_ent,
            sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa_ent,
            (sum(variazione_aumento_residuo) - sum(variazione_diminuzione_residuo))
            	variazione_residuo_ent,
            (sum(variazione_aumento_stanziato) - sum(variazione_diminuzione_stanziato))
            	variazione_stanziato_ent,       
            (sum(variazione_aumento_cassa) - sum(variazione_diminuzione_cassa))
            	variazione_cassa_ent                    
        from "BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by attoamm_anno_ent,
            attoamm_numero_ent, tipo_atto_ent, attoamm_oggetto_ent, 
            attoamm_id_ent,
            data_provv_var_ent, data_approvazione_provv_ent) entrate
    FULL JOIN 
               (select attoamm_anno attoamm_anno_spese,
                attoamm_numero attoamm_numero_spese, tipo_atto tipo_atto_spese, 
                attoamm_oggetto attoamm_oggetto_spese, 
                attoamm_id attoamm_id_spese,
                data_provv_var data_provv_var_spese, 
                data_approvazione_provv data_approvazione_provv_spese,
                sum(variazione_aumento_residuo) variazione_aumento_residuo_spese,
                sum(variazione_aumento_stanziato) variazione_aumento_stanziato_spese,
                sum(variazione_aumento_cassa) variazione_aumento_cassa_spese,
                sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo_spese,
                sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato_spese,
                sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa_spese,
                (sum(variazione_aumento_residuo) - sum(variazione_diminuzione_residuo))
            	variazione_residuo_spese,
            (sum(variazione_aumento_stanziato) - sum(variazione_diminuzione_stanziato))
            	variazione_stanziato_spese,       
            (sum(variazione_aumento_cassa) - sum(variazione_diminuzione_cassa))
            	variazione_cassa_spese                        
            from "BILR024_Allegato_7_Allegato_delibera_variazione_su_spese_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by attoamm_anno_spese,
                attoamm_numero_spese, tipo_atto_spese, attoamm_oggetto_spese, 
                attoamm_id_spese,
                data_provv_var_spese, data_approvazione_provv_spese) spese
    ON entrate.attoamm_id_ent=spese.attoamm_id_spese;   	
elsif  p_code_report = 'BILR149' then --Report BILR149
	return query 
    			select (
                         --CIST
                 '00001'  || 
                    --CENT codice ente 
                p_codice_ente  || 
                    --CESE codice esercizio
                p_anno_competenza  || 
                    -- NDEL Numero Delibera
                case when entrate.attoamm_id_ent IS NULL then
                    LPAD(spese.attoamm_numero_spese::varchar,7,'0')
                else LPAD(entrate.attoamm_numero_ent::varchar,7,'0') end || 
                    --SORG Organo deliberante
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- CTIPREC tipo record
                '0'  || 
                    -- DDEL Data delibera
               case when entrate.attoamm_id_ent IS NULL then
                    to_char(spese.data_provv_var_spese,'ddMMyyyy') 
                else to_char(entrate.data_provv_var_ent,'ddMMyyyy') end ||
                    -- ZDES descr delibera
               case when entrate.attoamm_id_ent IS NULL then
                    RPAD(left(spese.attoamm_oggetto_spese,50),50,' ')
                else RPAD(left(entrate.attoamm_oggetto_ent,50),50,' ') end || 
                    -- SORGAPP  Organo approvazione
                case when p_organo_provv is null or p_organo_provv = '' then 
                    ' ' else p_organo_provv  end || 
                    -- DDEL Data Approvazione Delibera.
               case when entrate.attoamm_id_ent IS NULL then
                    to_char(spese.data_approvazione_provv_spese,'ddMMyyyy')
                else to_char(entrate.data_approvazione_provv_ent,'ddMMyyyy') end || 
                    --DDATAPP  Numero Approvazione Delibera
                LPAD('0', 7, '0') || 
                    --IENTRES Importo entrate residuo               
                LPAD('0',17,'0') ||
                    --SENTRES Segno entrate residuo  
                ' ' || 
                    --IUSCRES Importo spese residuo
                LPAD('0',17,'0') ||
                    --SUSCRES Segno spese residuo 
                ' ' ||                            
                    --IENTCPT Importo entrate competenza                    
 			   case when entrate.attoamm_id_ent is NULL then
                    LPAD('0',17,'0')
			   else trim(replace(to_char(ABS(entrate.variazione_totale_entrate),
          				'000000000000000.00'),'.','')) end ||                                                   	
                    --SENTCPT Segno entrate competenza
               case when entrate.attoamm_id_ent IS NULL then
                    ' '
                else case when entrate.variazione_totale_entrate >=0 then '+'
                    else '-' end end ||
                    --IUSCCPT Importo spese competenza
                case when spese.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0')
                else trim(replace(to_char(ABS(spese.variazione_totale_spese),
          				'000000000000000.00'),'.','')) end ||
                    --SUSCCPT Segno spese competenza 
                case when spese.attoamm_id_spese IS NULL then
                    ' '
                else case when spese.variazione_totale_spese >=0 then '+'
                    else '-' end end ||   
                    --IENTCAS Importo entrate cassa 
                LPAD('0',17,'0') ||
                    --SENTCAS Segno entrate cassa
                ' ' ||  
                    --IUSCCAS Importo spese cassa   
                LPAD('0',17,'0') ||
                    --SUSCCAS Segno spese cassa 
                ' ' ||   
                    --KEYWEB Identificativo flusso web. NON OBBLIGATORIO.    
                RPAD(' ', 30, ' ')  ||
                    --CTIPFLU Identificativo tipo flusso.
                'D' ||
                    --SSBIL Segnale stato bilancio. NON OBBLIGATORIO. 
                ' ' || 
                    --STIPINV Indicatore tipo invio. NON OBBLIGATORIO.
                ' ' || 
                    --FILLER 
                RPAD(' ', 160, ' '))::varchar        	                                      
        from (select attoamm_anno attoamm_anno_ent,
            attoamm_numero attoamm_numero_ent, tipo_atto tipo_atto_ent, 
            attoamm_oggetto attoamm_oggetto_ent, 
            attoamm_id attoamm_id_ent,
            data_provv_var data_provv_var_ent, 
            data_approvazione_provv data_approvazione_provv_ent,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,            
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            (sum(variazione_aumento_stanziato) - sum(variazione_diminuzione_stanziato))
             	variazione_totale_entrate          
        from "BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by attoamm_anno_ent,
            attoamm_numero_ent, tipo_atto_ent, attoamm_oggetto_ent, 
            attoamm_id_ent,
            data_provv_var_ent, data_approvazione_provv_ent) entrate
    FULL JOIN 
               (select attoamm_anno attoamm_anno_spese,
                attoamm_numero attoamm_numero_spese, tipo_atto tipo_atto_spese, 
                attoamm_oggetto attoamm_oggetto_spese, 
                attoamm_id attoamm_id_spese,
                data_provv_var data_provv_var_spese, 
                data_approvazione_provv data_approvazione_provv_spese,
                sum(variazione_aumento_fpv) variazione_aumento_fpv,                
                sum(variazione_diminuzione_fpv) variazione_diminuzione_fpv ,
                (sum(variazione_aumento_stanziato) + sum(variazione_aumento_fpv) -
                 sum(variazione_diminuzione_stanziato) - sum(variazione_diminuzione_fpv))
                	variazione_totale_spese	                         
            from "BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by attoamm_anno_spese,
                attoamm_numero_spese, tipo_atto_spese, attoamm_oggetto_spese, 
                attoamm_id_spese,
                data_provv_var_spese, data_approvazione_provv_spese) spese
    ON entrate.attoamm_id_ent = spese.attoamm_id_spese;   
else
	record_t2sb20s:= 'Il REPORT '||p_code_report|| ' NON E'' GESTITO IN QUESTO FORMATO';
    return next;
    return;
        	
end if;


	

exception
    when syntax_error THEN
    	record_t2sb20s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	record_t2sb20s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

CREATE OR REPLACE FUNCTION siac.fnc_tracciato_t2sb21s (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar,
  p_codice_ente varchar
)
RETURNS TABLE (
  record_t2sb21s varchar
) AS
$body$
DECLARE

prefisso varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona prepara i dati del tracciato t2sb21s.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    In base al report richiama le procedure corrette.
    Funziona solo per i report BILR024 e BILR146.

*/
	
if p_code_report = 'BILR024' then
    return query 
      with query_tot as (
      	select 'E' tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
/*  SIAC-7678 26/06/2020:
	Sul file delle variazioni "normali" il tag 'NCAP' che sta sul record di 
    dettaglio (da posizione 27 a 33) deve essere allineato a dx e preceduto 
    dai necessari zeri per riempire i 7 campi previsti.            
             COALESCE(tipologia_code,'') */
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else '' end codifica_bil, 
            COALESCE(tipologia_desc,'') descr_codifica_bil,
            sum(variazione_aumento_residuo) variazione_aumento_residuo,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            sum(variazione_aumento_cassa) variazione_aumento_cassa,
            sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
        from "BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil
     UNION select 'S' tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil,
                COALESCE(titusc_desc,'') descr_codifica_bil,
                sum(variazione_aumento_residuo) variazione_aumento_residuo,
                sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum(variazione_aumento_cassa) variazione_aumento_cassa,
                sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
                sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
            from "BILR024_Allegato_7_Allegato_delibera_variazione_su_spese_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                codifica_bil, descr_codifica_bil
      order by tipo_record, attoamm_id, codifica_bil)
       select (         	
              --CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(query_tot.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || 
              -- CTIPREC tipo record
          '1'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (1= Entrata - 2 = Uscita)
          case when query_tot.tipo_record = 'E' then '1'
          		else '2' end ||
			  -- NCAP Codifica di Bilancio
          LPAD(query_tot.codifica_bil, 7, '0') ||
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo 
/*  SIAC-7678 26/06/2020:
	Sempre sul file delle variazioni "normali" il tag 'NRES' (da posizione 
    37 per 4) deve essere compilato solo sui record relativamente ai residui.
    ....se il capitolo interessato e' la competenza deve essere compilato 
    con quattro zeri              
          p_anno_competenza || */ 
          '0000' ||
          		--IPIUCPT Importo Variazione PIU' Competenza
          trim(replace(to_char(query_tot.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENCPT Importo Variazione MENO Competenza
          trim(replace(to_char(query_tot.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
           		--IPIUCAS Importo Variazione PIU' Cassa
          trim(replace(to_char(query_tot.variazione_aumento_cassa ,
          		'000000000000000.00'),'.','')) ||
          		--IMENCAS Importo Variazione MENO Cassa
          trim(replace(to_char(query_tot.variazione_diminuzione_cassa ,
          		'000000000000000.00'),'.','')) ||
         		--ZDES Descrizione Codifica di Bilancio
          RPAD(left(query_tot.descr_codifica_bil,90),90,' ') ||
                --ZDESBL Descrizione Codifica di Bilancio (Bilingue)
          RPAD(' ',90,' ') || 
          		--CMEC Codice Meccanografico
          RPAD('0', 7, '0') ||
                -- SRILIVA Segnale Rilevanza IVA (0 = NO - 1 = SI) NON OBBL.
          ' ' ||
          		--ISTACPT  Importo Stanziamento di Competenza
          LPAD('0', 17,'0') ||
          		--ISTACAS  Importo Stanziamento di Cassa
          LPAD('0', 17,'0') ||
          		--NCNTRIF   Numero Conto di Riferimento
          LPAD('0', 7,'0') ||
          		-- STIPCNT  Tipo Conto di Riferimento (0 = ordinario - 1 = vincolato)
          ' ' ||
          		--ISCOCAP   Importo limite Sconfino
          LPAD('0', 17,'0') ||
          		--IIMP   Importo Impegnato
          LPAD('0', 17,'0') ||
          		--IFNDVIN   Importo Fondo Vincolato
          LPAD('0', 17,'0') ||
           		--FILLER 
          RPAD(' ', 11, ' ')
          )::varchar           
       from query_tot;
else --BILR149                
return query 
      with query_tot as (
      	select 'E' tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
/*  SIAC-7678 26/06/2020:
	Sul file delle variazioni "normali" il tag 'NCAP' che sta sul record di 
    dettaglio (da posizione 27 a 33) deve essere allineato a dx e preceduto 
    dai necessari zeri per riempire i 7 campi previsti.            
             COALESCE(tipologia_code,'') */
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else '' end codifica_bil, 
            COALESCE(tipologia_desc,'') descr_codifica_bil,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            0 variazione_aumento_fpv,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            0 variazione_diminuzione_fpv                             
        from "BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil
     UNION select 'S' tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil,
                COALESCE(titusc_desc,'') descr_codifica_bil,
                	--l'importo presentato delle variazioni deve comprendere
                    --lo stanziato NON FPV piu' quello FPV.
                sum(variazione_aumento_stanziato+variazione_aumento_fpv) variazione_aumento_stanziato,
                sum(variazione_aumento_fpv) variazione_aumento_fpv,
                sum(variazione_diminuzione_stanziato+variazione_diminuzione_fpv) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_fpv) variazione_diminuzione_fpv                          
            from "BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                codifica_bil, descr_codifica_bil
      order by tipo_record, attoamm_id, codifica_bil)
       select (         	
              --CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(query_tot.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || 
              -- CTIPREC tipo record
          '1'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (1= Entrata - 2 = Uscita)
          case when query_tot.tipo_record = 'E' then '1'
          		else '2' end ||
			  -- NCAP Codifica di Bilancio
          LPAD(query_tot.codifica_bil, 7, '0') ||
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo 
/*  SIAC-7678 26/06/2020:
	Sempre sul file delle variazioni "normali" il tag 'NRES' (da posizione 
    37 per 4) deve essere compilato solo sui record relativamente ai residui.
    ....se il capitolo interessato e' la competenza deve essere compilato 
    con quattro zeri              
          p_anno_competenza || */ 
          '0000' ||                
          		--IPIUCPT Importo Variazione PIU' Competenza
          trim(replace(to_char(query_tot.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENCPT Importo Variazione MENO Competenza
          trim(replace(to_char(query_tot.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
           		--IPIUCAS Importo Variazione PIU' Cassa
          LPAD('0',17,'0') ||
          		--IMENCAS Importo Variazione MENO Cassa
          LPAD('0',17,'0') ||
         		--ZDES Descrizione Codifica di Bilancio
          RPAD(left(query_tot.descr_codifica_bil,90),90,' ') ||
                --ZDESBL Descrizione Codifica di Bilancio (Bilingue)
          RPAD(' ',90,' ') || 
          		--CMEC Codice Meccanografico
          RPAD('0', 7, '0') ||
                -- SRILIVA Segnale Rilevanza IVA (0 = NO - 1 = SI) NON OBBL.
          ' ' ||
          		--ISTACPT  Importo Stanziamento di Competenza
          LPAD('0', 17,'0') ||
          		--ISTACAS  Importo Stanziamento di Cassa
          LPAD('0', 17,'0') ||
          		--NCNTRIF   Numero Conto di Riferimento
          LPAD('0', 7,'0') ||
          		-- STIPCNT  Tipo Conto di Riferimento (0 = ordinario - 1 = vincolato)
          ' ' ||
          		--ISCOCAP   Importo limite Sconfino
          LPAD('0', 17,'0') ||
          		--IIMP   Importo Impegnato
          LPAD('0', 17,'0') ||
          		--IFNDVIN   Importo Fondo Vincolato
          LPAD('0', 17,'0') ||
           		--FILLER 
          RPAD(' ', 11, ' ')
          )::varchar           
       from query_tot;                   
                
end if;
	

exception
    when syntax_error THEN
    	record_t2Sb21s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	record_t2Sb21s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

CREATE OR REPLACE FUNCTION siac.fnc_tracciato_t2sb22s (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar,
  p_codice_ente varchar
)
RETURNS TABLE (
  record_t2sb22s varchar
) AS
$body$
DECLARE

prefisso varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona prepara i dati del tracciato t2sb22s.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    In base al report richiama le procedure corrette.
    Funziona solo per il report BILR139.

*/
	
if p_code_report = 'BILR139' then
    return query 
      select (--CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(spese.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
             /* SIAC-7678 26/06/2020:
              Sul file di variazione dei fondi vincolati il tag 'SORG' 
              (posizione 24) non deve essere valorizzato 
              (l'avevano compilato - in buona fede - con G). 
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || */
          ' ' ||
              -- CTIPREC tipo record
          '2'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (fisso 2 = Uscita)
          '2'  ||
			  -- NCAP Codifica di Bilancio
          LPAD(spese.codifica_bil, 7, '0') ||
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo ??
          p_anno_competenza ||
          		--IPIUFNV Importo Variazione PIU' fondo vincolato
          trim(replace(to_char(spese.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENFNV Importo Variazione MENO Competenza
          trim(replace(to_char(spese.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
                --ZDES Descrizione delibera
          RPAD(left(spese.attoamm_oggetto,50),50,' ') ||
                --FILLER 
          RPAD(' ', 276, ' '))::varchar
      from (
      	select  attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            programma_code||titusc_code codifica_bil, 
            titusc_desc descr_codifica_bil,
            sum(variazione_aumento_residuo) variazione_aumento_residuo,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            sum(variazione_aumento_cassa) variazione_aumento_cassa,
            sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
        from "BILR139_Allegato_8_Allegato_delibera_variazion_su_spese_fpv_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by  attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil
      order by attoamm_id, codifica_bil) spese;
else
	record_t2sb22s:= 'Il REPORT '||p_code_report|| ' NON E'' GESTITO IN QUESTO FORMATO';
    return next;
    return;	       
end if;
	

exception
    when syntax_error THEN
    	record_t2sb22s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	record_t2sb22s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

--SIAC-7678 - Maurizio - FINE.








CREATE OR REPLACE FUNCTION fnc_siac_bko_inserisci_azione(codice text, descrizione text, url text, codice_tipo text, codice_gruppo text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
 
/* Esempio:
 * 
 * select fnc_siac_bko_inserisci_azione('OP-BKOF014-annullaAttivazioniContabili', 'Annulla attivazioni contabili', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
 * 
 */

begin
	
 INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) select codice, descrizione, ta.azione_tipo_id, ga.gruppo_azioni_id, url, CURRENT_DATE,
 e.ente_proprietario_id, 'admin'
  from siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
  where  ta.ente_proprietario_id = e.ente_proprietario_id
  and ga.ente_proprietario_id = e.ente_proprietario_id
  and ta.azione_tipo_code = codice_tipo
  and ga.gruppo_azioni_code = codice_gruppo
  and not exists (select 1 from siac_t_azione z where z.azione_tipo_id=ta.azione_tipo_id
  and z.azione_code=codice);
  	
  return 'azione creata o esistente';

end;
$function$
;



select fnc_siac_bko_inserisci_azione('OP-BKOF014-annullaAttivazioniContabili', 'Documento - Backoffice annulla attivazioni contabili', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
	

-- SIAC-7599 INIZIO
/****** OP-SPE-gestImprROR *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-SPE-gestImprROR','Ricerca Impegni ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-SPE-gestImprROR'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-SPE-gestImprROR'
 and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;

/****** OP-SPE-gestImpRORdecentrato *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-SPE-gestImpRORdecentrato','Ricerca Impegno ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-SPE-gestImpRORdecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

 update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-SPE-gestImpRORdecentrato'
  and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;


/****** OP-ENT-gestAccROR *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-ENT-gestAccROR','Ricerca Accertamento ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-ENT-gestAccROR'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
 
 update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-ENT-gestAccROR'
 and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;



/****** OP-ENT-gestAccRORdecentrato *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-ENT-gestAccRORdecentrato','Ricerca Accertamento ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-ENT-gestAccRORdecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
 

update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-ENT-gestAccRORdecentrato'
 and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;
--SIAC-7599 fine

--SIAC-7256 - Maurizio - INIZIO.

CREATE OR REPLACE FUNCTION siac.fnc_configura_indicatori (
  p_ente_prop_id integer,
  p_anno varchar,
  p_login varchar,
  out codicerisultato varchar,
  out descrrisultato varchar
)
RETURNS record AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;   
    anno1 varchar;
    anno2 varchar;
    anno3 varchar;
    entePropIdCorr integer;
    elencoEnti record;
    annoDaInserire integer;
    proseguiGestione boolean;
	var_anno_bil_prev varchar;
    esisteNumAnniBilPrev integer;
    cod_esito varchar;
    desc_esito varchar;
    conta integer;
  
  
BEGIN
 
/*
 Procedura per configurare i dati degli indicatori.
 La procedura esegue le seguenti operazioni:
 - crea il parametro GESTIONE_NUM_ANNI_BIL_PREV_INDIC_anno se non  esiste ancora;
 - gli indicatori sintetici per l'anno di bilancio in input
 - configura  i dati del Rendiconto di Entrata e Spesa per i 3 anni precedenti quello
 	del bilancio, lanciando le rispettive procedure.
 La procedura presuppone che per l'ente in questione esistano gia' gli indicatori sintetici 
 sulla tabella "siac_t_voce_conf_indicatori_sint" che saranno configurati sulla tabella
  "siac_t_conf_indicatori_sint" per l'anno di bilancio in input.
 
 Parametri:
 	- p_ente_prop_id; ente da configurare; indicare 0 per configurarli tutti.  
  	- p_anno; anno di bilancio da configurare.
    - p_login; stringa da inserire nel campo login_operazione per i nuovi record.
  
 La procedura segnala l'esito delle operazioni:
 - codicerisultato = 0 se OK, -1 se errore;
 - descrrisultato = descrizione dell'errore o elenco degli enti configurati e la stringa
 	che indica che le operazioni sii sono concluse correttamente ad esempio:
      Ente 2 - Operazioni concluse correttamente
      Ente 15 - Operazioni concluse correttamente
     
 Se per qualche motivo si verificano errori per uno degli enti la procedura si interrompe.
  
*/

anno1:=(p_anno::integer -1)::varchar;  
anno2:=(p_anno::integer -2)::varchar;    
anno3:=(p_anno::integer -3)::varchar; 
var_anno_bil_prev:='CONF_NUM_ANNI_BIL_PREV_INDIC_'||p_anno;
descrrisultato:='';

-- ciclo sugli enti.	
-- se p_ente_prop_id = 0, voglio configurare tutti gli enti.
FOR elencoEnti IN
	SELECT *
    FROM siac_t_ente_proprietario a
    WHERE a.data_cancellazione IS NULL
    	AND (a.ente_proprietario_id = p_ente_prop_id AND p_ente_prop_id <> 0) OR
        	p_ente_prop_id=0
    ORDER BY a.ente_proprietario_id
loop

	entePropIdCorr :=elencoEnti.ente_proprietario_id;
    raise notice 'Ente = %', entePropIdCorr;
    esisteNumAnniBilPrev:=0;
    if descrrisultato = '' then	 
    	descrrisultato:='Ente '|| entePropIdCorr;
    else 
    	descrrisultato:=descrrisultato||chr(13)||'Ente '|| entePropIdCorr;
    end if;
    
	--Inserisco la variabile che dice quanti sono gli anni di rendiconto.
  INSERT INTO siac_d_gestione_livello (
    gestione_livello_code, gestione_livello_desc, gestione_tipo_id,
    validita_inizio, ente_proprietario_id, data_creazione,
    data_modifica, login_operazione)
  SELECT
   var_anno_bil_prev, '3', a.gestione_tipo_id, now(),  a.ente_proprietario_id, 
      now(), now(),  p_login
   FROM siac_d_gestione_tipo a
   WHERE  a.ente_proprietario_id=entePropIdCorr
      and a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC'
      and a.data_cancellazione IS NULL
      and not exists (select 1
        from siac_d_gestione_livello z
        where z.ente_proprietario_id=a.ente_proprietario_id
        and z.gestione_livello_code=var_anno_bil_prev);

      --verifico inserimento della variabile.
      conta:=0;
      select count(*)
          into conta
      from siac_d_gestione_livello z
      where z.ente_proprietario_id=entePropIdCorr
      and z.gestione_livello_code=var_anno_bil_prev;
  
      if conta = 0 then
          codicerisultato=-1;
          descrrisultato:=descrrisultato||' - Errore: variabile '|| var_anno_bil_prev|| ' non inserita. - Operazioni interrotte';
          RETURN;
      end if;

    		-- inserisco il record nella tabella di relazione.
	INSERT INTO siac_r_gestione_ente (
      gestione_livello_id,  validita_inizio, ente_proprietario_id,
      data_creazione,  data_modifica, login_operazione)
     SELECT
        gestione_livello_id, now(),  ente_proprietario_id, now(), now(), p_login
     from siac_d_gestione_livello a
        where  a.ente_proprietario_id=entePropIdCorr
            and a.gestione_livello_code =var_anno_bil_prev
            and a.data_cancellazione IS NULL
        and not exists (select 1
          from siac_r_gestione_ente z
          where z.ente_proprietario_id=a.ente_proprietario_id
          and z.gestione_livello_id=a.gestione_livello_id);

    --verifico inserimento nella tabella di relazione.
    conta:=0;          
    select count(*)
        into conta
    from siac_r_gestione_ente a, siac_d_gestione_livello b
    where b.gestione_livello_id=a.gestione_livello_id
    and a.ente_proprietario_id=entePropIdCorr
    and b.gestione_livello_code=var_anno_bil_prev;

    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: relazione su siac_r_gestione_ente per la variabile '|| var_anno_bil_prev|| ' Non inserita. - Operazioni interrotte';
        RETURN;
    end if;          
      
         -- inserisco gli indicatori sintetici sulla tabella siac_t_conf_indicatori_sint
         -- per l'anno di bilancio in input.
         -- sono prese le voci presenti su siac_t_voce_conf_indicatori_sint che quindi
         -- DEVONO esistere per l'ente gestito.
         -- Se non esistono occorre prima crearle magari copiandolo da un altro ente.
    INSERT INTO  siac_t_conf_indicatori_sint (
    voce_conf_ind_id,
      bil_id,
      conf_ind_valore_anno,
      conf_ind_valore_anno_1,
      conf_ind_valore_anno_2,
      conf_ind_valore_tot_miss_13_anno,
      conf_ind_valore_tot_miss_13_anno_1 ,
      conf_ind_valore_tot_miss_13_anno_2 ,
      conf_ind_valore_tutte_spese_anno ,
      conf_ind_valore_tutte_spese_anno_1 ,
      conf_ind_valore_tutte_spese_anno_2 ,
      validita_inizio,
      validita_fine,
      ente_proprietario_id,
      data_creazione,
      data_modifica,
      data_cancellazione,
      login_operazione)
    SELECT t_voce_ind.voce_conf_ind_id, t_bil.bil_id, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL,
        now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, p_login
    FROM siac_t_ente_proprietario t_ente,
        siac_t_bil t_bil,
        siac_t_periodo t_periodo,
        siac_t_voce_conf_indicatori_sint t_voce_ind
    where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
        and t_bil.periodo_id=t_periodo.periodo_id
        and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
        and t_ente.ente_proprietario_id = entePropIdCorr
        and t_periodo.anno=p_anno    	
        and t_ente.data_cancellazione IS NULL
        and	t_bil.data_cancellazione IS NULL
        and	t_periodo.data_cancellazione IS NULL
        and t_voce_ind.data_cancellazione IS NULL
        and not exists (select 1
          from siac_t_conf_indicatori_sint z
          where z.bil_id=t_bil.bil_id
          and z.ente_proprietario_id=t_ente.ente_proprietario_id
          and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);
          
    --verifico inserimento degli indicatori sintetici.
    conta:=0;          
    select count(*)
        into conta
    from siac_t_conf_indicatori_sint ind,
    	siac_t_bil t_bil,
        siac_t_periodo t_periodo
    where ind.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
    	and ind.ente_proprietario_id=entePropIdCorr
    	and t_periodo.anno=p_anno
        and ind.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL;

    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: indicatori sintetici non inseriti. - Operazioni interrotte';
        RETURN;
    end if;           
         
     
 	--CONFIGURAZIONE dati del rendiconto per gli INDICATORI ANALITICI. 
    	--Spesa anno-1     
    select *
    	into cod_esito, desc_esito 
    from  "fnc_configura_indicatori_spesa"(entePropIdCorr,p_anno,anno1,false, false)a;--a.codicerisultato, a.descrrisultato
	        
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di spesa - anno '||
                anno1||': '||desc_esito;	
        return;
    end if;
     
    	--Spesa anno-2
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_spesa"(entePropIdCorr,p_anno,anno2,false, false);
   
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di spesa - anno '||
                anno2||': '||desc_esito;	
        return;
    end if;
        
    	--Spesa anno-3 
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_spesa"(entePropIdCorr,p_anno,anno3,false, false);
		
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di spesa - anno '||
                anno3||': '||desc_esito;	
        return;
    end if;

--verifico inserimento di dati di rendiconto di spesa per gli indicatori analitici
    conta:=0;          
    select count(*)
        into conta
    from siac_t_conf_indicatori_spesa ind,
    	siac_t_bil t_bil,
        siac_t_periodo t_periodo
    where ind.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
    	and ind.ente_proprietario_id=entePropIdCorr
    	and t_periodo.anno=p_anno
        and ind.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL;
        
    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: dati del rendiconto di spesa non inseriti. - Operazioni interrotte';
        RETURN;
    end if;
   
		--Entrata anno-1   
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_entrata"(entePropIdCorr,p_anno,anno1,false, false);
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di entrata - anno '||
                anno1||': '||desc_esito;	
        return;
    end if;
    
    	--Entrata anno-2
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_entrata"(entePropIdCorr,p_anno,anno2,false, false);
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di entrata - anno '||
                anno2||': '||desc_esito;	
        return;
    end if;
    
    	--Entrata anno-3
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_entrata"(entePropIdCorr,p_anno,anno3,false, false);  
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di entrata - anno '||
                anno3||': '||desc_esito;	
        return;
    end if;     
       
--verifico inserimento di dati di rendiconto di entrata per gli indicatori analitici
    conta:=0;          
    select count(*)
        into conta
    from siac_t_conf_indicatori_entrata ind,
    	siac_t_bil t_bil,
        siac_t_periodo t_periodo
    where ind.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
    	and ind.ente_proprietario_id=entePropIdCorr
    	and t_periodo.anno=p_anno
        and ind.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL;
        
    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: dati del rendiconto di entrata non inseriti. - Operazioni interrotte';
        RETURN;
    end if;
    
    descrrisultato:=descrrisultato|| ' - Operazioni concluse correttamente';
end loop;
      
codicerisultato:=0;

EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
        codicerisultato:=-1;
        descrrisultato:='Nessun dato trovato';
		return;
	when others  THEN
    	codicerisultato:=-1;
    	descrrisultato:= SQLSTATE;
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);        
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

--SIAC-7256 - Maurizio - FINE.

-- SIAC -7562 ENG INIZIO
SELECT * FROM fnc_dba_add_column_params ('siac_t_doc', 'data_stato_sdi' , 'TIMESTAMP WITHOUT TIME ZONE');
-- SIAC -7562 ENG FINE

--SIAC-7349 modifiche INIZIO
-- Aggiunte/modificate per versione 4.26
    
-- start fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz(
	id_in integer,
	idcomp_in integer[])
    RETURNS TABLE(elemdetcompid integer, elemdetcompdesc character varying, annoimpegnato integer, impegnatodefinitivo numeric, elemdetcompmacrotipodesc character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nel triennio
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	

	sidcomp_in:=array_to_string(idcomp_in, ',');
    	strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';
	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
	strMessaggio:=strMessaggio || 'annoBilancio='||annoBilancio|| '.';

		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
				   '. Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo - Anno N:
	-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
	-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
	--	e che "copia" gli impegni dell'anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
	-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
	-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
	--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
	-- In entrambe c'e' sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
	-- c'e' anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';
	
	impegniDaRibaltamento:=0;
	pluriennaliDaRibaltamento:=0;
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where 
	fb.movgest_Ts_id is not null
	and fb.bil_id = bilancioId
	and fb.data_cancellazione is null
	and fb.validita_fine is null;

	strMessaggio:=strMessaggio || 'impegniDaRibaltamento='||impegniDaRibaltamento|| '.';
	strMessaggio:=strMessaggio || 'pluriennaliDaRibaltamento='||pluriennaliDaRibaltamento|| '.';

	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
		annoMovimento:=annoBilancio;
	end if;
	
	strMessaggio:=strMessaggio || 'annoEsercizio='||annoEsercizio|| '.';
	strMessaggio:=strMessaggio || 'annoMovimento='||annoMovimento|| '.';


	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';
	strMessaggio:=strMessaggio || 'bilIdElemGestEq='||bilIdElemGestEq|| '.';


	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;
	strMessaggio:=strMessaggio || 'elemIdGestEq='||elemIdGestEq|| '.';

	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2)
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		strMessaggio:=strMessaggio || 'esisteRmovgestidelemid='||esisteRmovgestidelemid|| '.';


		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc,
				 tb.movgest_anno as annualita
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id, b.movgest_anno
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq 
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id<>movGestStatoIdAnnullato
					  and d.movgest_stato_id<>movGestStatoIdProvvisorio
					  and b.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2)
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id, -- SIAC-7349
								b.movgest_anno
					) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
				 order by t.movgest_ts_tipo_code desc
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

						select tb.importo into importoModifDelta
						 from
						 (
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, 
								 siac_t_movgest mov,
								 siac_t_movgest_ts ts,
								 siac_r_movgest_ts_stato rstato,
								 siac_t_movgest_ts_det tsdet,
								 siac_t_movgest_ts_det_mod moddet,
								 siac_t_modifica mod, 
								 siac_r_modifica_stato rmodstato,
								 siac_r_atto_amm_stato attostato, 
								 siac_t_atto_amm atto,
								 siac_d_modifica_tipo tipom
							where 
								rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
								and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
								and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
								and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
								and   mod.mod_id=rmodstato.mod_id
								and   atto.attoamm_id=mod.attoamm_id
								and   attostato.attoamm_id=atto.attoamm_id
								and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
								and   tipom.mod_tipo_id=mod.mod_tipo_id
								and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
								-- date
								and rbil.data_cancellazione is null
								and rbil.validita_fine is null
								and mov.data_cancellazione is null
								and mov.validita_fine is null
								and ts.data_cancellazione is null
								and ts.validita_fine is null
								and rstato.data_cancellazione is null
								and rstato.validita_fine is null
								and tsdet.data_cancellazione is null
								and tsdet.validita_fine is null
								and moddet.data_cancellazione is null
								and moddet.validita_fine is null
								and mod.data_cancellazione is null
								and mod.validita_fine is null
								and rmodstato.data_cancellazione is null
								and rmodstato.validita_fine is null
								and attostato.data_cancellazione is null
								and attostato.validita_fine is null
								and atto.data_cancellazione is null
								and atto.validita_fine is null
								group by ts.movgest_ts_tipo_id
							  ) tb, siac_d_movgest_ts_tipo tipo
							  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
							  order by tipo.movgest_ts_tipo_code desc
							  limit 1;		

						if importoModifDelta is null then importoModifDelta:=0; end if;
						  /*Aggiunta delle modifiche ECONB*/
						 -- anna_economie inizio
						select tb.importo into importoModifINS
						from
						(
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
							siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
							siac_t_movgest_ts_det_mod moddet,
							siac_t_modifica mod, siac_r_modifica_stato rmodstato,
							siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
							siac_d_modifica_tipo tipom
						where rbil.elem_id=elemIdGestEq
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
						and   mov.movgest_anno=annoMovimento::integer
						and   mov.bil_id=bilancioId
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
						and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
					   and   tipom.mod_tipo_id=mod.mod_tipo_id
					   and   tipom.mod_tipo_code = 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
					   group by ts.movgest_ts_tipo_id
					 ) tb, siac_d_movgest_ts_tipo tipo
					 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					 order by tipo.movgest_ts_tipo_code desc
					 limit 1;

					 if importoModifINS is null then 
						importoModifINS = 0;
					 end if;

					end if;		
	
			--Fix MR adeguamento sprint 5
			-- Mon restituiamo piu' al valore impegnato le modifiche provvisorie e le ECONB
           		importoModifDelta:=0;
            		importoModifINS:=0;
            --
			
			annoimpegnato:=impComponenteRec.annualita;
			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	

	end loop;
	end if;
	end if;

	return;
 

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz(integer, integer[])
    OWNER TO siac;

-- end fnc_siac_impegnatodefinitivoup_comp_triennio_nostanz

-- start fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz(
	id_in integer,
	idcomp_in integer[])
    RETURNS TABLE(elemdetcompid integer, elemdetcompdesc character varying, annoimpegnato integer, impegnatodefinitivo numeric, elemdetcompmacrotipodesc character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';
modStatoVId integer:=0;
attoAmmStatoPId integer:=0;
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
flagDeltaPagamenti integer:=0;
importoImpegnato numeric:=0;
importoPagatoDelta numeric:=0;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;
-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

sidcomp_in  varchar:=null;
strMessaggio varchar(1500):=null;

impComponenteRec record;

BEGIN

/* Calcola impegnato definitivo per quelle componenti per le quali pur non essendoci stanziamento
 * esistono quote di impegnato nel triennio
 * Le componenti per le quali esiste stanziamento (e quindi da non considerare) sono passate in input nell'array idcomp_in
 * NOTA: per problemi Java/Hibernate idcomp_in non puo essere un array vuoto, quindi 
 *		l'array in input conterra' sempre la componente fittizia idcomp = -1
 */
-- CALCOLO IMPEGNATO DEFINITIVO 
-- Stiamo sempre parlando di impegnato sul capitolo di gestione equivalente	

	sidcomp_in:=array_to_string(idcomp_in, ',');
    	strMessaggio:='Calcolo totale impegnato definitovo elem_id='||id_in|| ' escludo idcomp_in='||sidcomp_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;
	strMessaggio:=strMessaggio || 'annoBilancio='||annoBilancio|| '.';

		  

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||
 
 				   '. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;


	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in||

				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato definitivo elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  ||'. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P; 
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;
	 
	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
              ||'. Calcolo modStatoVId per mod_stato_code=VALIDO.';
	 select d.mod_stato_id into strict modStatoVId
	 from siac_d_modifica_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.mod_stato_code=STATO_MOD_V;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	 select d.attoamm_stato_id into strict attoAmmStatoPId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||' escludo idcomp_in='||sidcomp_in
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINITIVO';
	 select d.attoamm_stato_id into strict attoAmmStatoDId
	 from siac_d_atto_amm_stato d
	 where d.ente_proprietario_id=enteProprietarioId
	 and   d.attoamm_stato_code=STATO_ATTO_D;

 	-- Calcolo Impegnato definitivo 

	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in;
	
	importoCurAttuale:=0;	
	importoModifDelta:=0;
	importoModifINS := 0;
	
	-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
	
	strMessaggio:=strMessaggio || 'annoEsercizio='||annoEsercizio|| '.';
	strMessaggio:=strMessaggio || 'annoMovimento='||annoMovimento|| '.';


	strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				   '. Calcolo bilancioId per annoEsercizio='||annoEsercizio
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
    -- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';
	strMessaggio:=strMessaggio || 'bilIdElemGestEq='||bilIdElemGestEq|| '.';


	  -- lettura elemIdGestEq
	 strMessaggio:='Calcolo impegnato competenza UG.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

	 select bilelem.elem_id into elemIdGestEq
	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
	 where bilElem.elem_code=elemCode
	   and bilElem.elem_code2=elemCode2
	   and bilElem.elem_code3=elemCode3
	   and bilElem.ente_proprietario_id=enteProprietarioId
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and bilElem.bil_id=bilIdElemGestEq
	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;
	strMessaggio:=strMessaggio || 'elemIdGestEq='||elemIdGestEq|| '.';


	if NOT FOUND THEN
		impegnatoDefinitivo:=0;  
	else
	
		strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento|| 
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid 
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2) 
			and NOT (el.elem_det_comp_tipo_id = ANY( idcomp_in)) --SIAC-7349
			;
		
		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		strMessaggio:=strMessaggio || 'esisteRmovgestidelemid='||esisteRmovgestidelemid|| '.';


		if esisteRmovgestidelemid <>0 then
 			impegnatoDefinitivo:=0;
			strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'escludo idcomp_in='||sidcomp_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			/* Versione con group by per le componenti non da escludere e ciclo per ogni componente */
			for impComponenteRec in
			 (
				select tb.elem_det_comp_tipo_id as compId, 
				 g.elem_det_comp_tipo_desc as compDesc, 
				 tb.importo as importoCurAttuale,
				 h.elem_det_comp_macro_tipo_desc as compMacroTipoDesc,
				 tb.movgest_anno as annualita
				from (
				  select
					  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id, a.elem_det_comp_tipo_id, b.movgest_anno
				  from
					  siac_r_movgest_bil_elem a,
					  siac_t_movgest b,
					  siac_t_movgest_ts c,
					  siac_r_movgest_ts_stato d,
					  siac_t_movgest_ts_det e,
					  siac_d_movgest_ts_det_tipo f
				  where
					  b.movgest_id=a.movgest_id 
					  and a.elem_id=elemIdGestEq 
					  and NOT( a.elem_det_comp_tipo_id = ANY(idcomp_in)) --SIAC-7349 --id componente diversa da quella ricevuta in input
					  and b.bil_id = bilIdElemGestEq
					  and b.movgest_tipo_id=movGestTipoId
					  and d.movgest_stato_id<>movGestStatoIdAnnullato
					  and d.movgest_stato_id<>movGestStatoIdProvvisorio
					  and b.movgest_anno IN (annoMovimento::integer,  annoMovimento::integer+1, annoMovimento::integer+2)
					  and c.movgest_id=b.movgest_id
					  and d.movgest_ts_id=c.movgest_ts_id
					  and d.validita_fine is null
					  and e.movgest_ts_id=c.movgest_ts_id
					  and a.data_cancellazione is null
					  and b.data_cancellazione is null
					  and c.data_cancellazione is null
					  and e.data_cancellazione is null
					  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
					  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
					  group by 	c.movgest_ts_tipo_id, 
								a.elem_det_comp_tipo_id, -- SIAC-7349
								b.movgest_anno
					) tb, 
					siac_d_movgest_ts_tipo t,
					siac_d_bil_elem_det_comp_tipo g,
				 	siac_d_bil_elem_det_comp_macro_tipo h
				where 
					tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
					and g.elem_det_comp_tipo_id = tb.elem_det_comp_tipo_id --SIAC-7349 recupera anche la descrizione della componente
					and g.elem_det_comp_macro_tipo_id = h.elem_det_comp_macro_tipo_id --SIAC-7349 recupera anche la descrizione del macrotipo della componente
				 order by t.movgest_ts_tipo_code desc
 			) 
			loop
			

					-- 02.02.2016 Sofia JIRA 2947
					 if impComponenteRec.importoCurAttuale is null then impComponenteRec.importoCurAttuale:=0; end if;

					 -- 16.03.2017 Sofia JIRA-SIAC-4614
					-- if importoCurAttuale>0 then
					 if impComponenteRec.importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

						strMessaggio:='Calcolo totale impegnato definitvo elem_id='||id_in||'  impComponenteRec.compId='||impComponenteRec.compId||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Calcolo totale modifiche su atti provvisori per annoMovimento='||annoMovimento||'.';

						select tb.importo into importoModifDelta
						 from
						 (
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, 
								 siac_t_movgest mov,
								 siac_t_movgest_ts ts,
								 siac_r_movgest_ts_stato rstato,
								 siac_t_movgest_ts_det tsdet,
								 siac_t_movgest_ts_det_mod moddet,
								 siac_t_modifica mod, 
								 siac_r_modifica_stato rmodstato,
								 siac_r_atto_amm_stato attostato, 
								 siac_t_atto_amm atto,
								 siac_d_modifica_tipo tipom
							where 
								rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
								and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349 deve essere sulla compoenente del record 
								and	  mov.movgest_id=rbil.movgest_id
								and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
								and   mov.movgest_anno>annoMovimento::integer -- anno dell impegno = annoMovimento 
								and   mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
								and   ts.movgest_id=mov.movgest_id
								and   rstato.movgest_ts_id=ts.movgest_ts_id
								and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- Impegno non ANNULLATO
								and   rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
								and   tsdet.movgest_ts_id=ts.movgest_ts_id
								and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
								and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
								-- SIAC-7349 Prendo tutti gli importi, sia con segno negativo che con segno positivo
								-- La loro somma produce il valore importoModifDelta che devo sottrarre all'impegnato calcolato
								-- ad esempio: modifiche su atto provv +100, -322 -> somma -222 si tratta di un delta che devo sottrarre
								-- all'impegnato calcolato = impegnato calcolato - (-222) = +222 (aggiungo quello che avevo tolto)
								-- and   moddet.movgest_ts_det_importo<0 -- importo negativo
								and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
								and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
								and   mod.mod_id=rmodstato.mod_id
								and   atto.attoamm_id=mod.attoamm_id
								and   attostato.attoamm_id=atto.attoamm_id
								and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
								and   tipom.mod_tipo_id=mod.mod_tipo_id
								and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
								-- date
								and rbil.data_cancellazione is null
								and rbil.validita_fine is null
								and mov.data_cancellazione is null
								and mov.validita_fine is null
								and ts.data_cancellazione is null
								and ts.validita_fine is null
								and rstato.data_cancellazione is null
								and rstato.validita_fine is null
								and tsdet.data_cancellazione is null
								and tsdet.validita_fine is null
								and moddet.data_cancellazione is null
								and moddet.validita_fine is null
								and mod.data_cancellazione is null
								and mod.validita_fine is null
								and rmodstato.data_cancellazione is null
								and rmodstato.validita_fine is null
								and attostato.data_cancellazione is null
								and attostato.validita_fine is null
								and atto.data_cancellazione is null
								and atto.validita_fine is null
								group by ts.movgest_ts_tipo_id
							  ) tb, siac_d_movgest_ts_tipo tipo
							  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
							  order by tipo.movgest_ts_tipo_code desc
							  limit 1;		

						if importoModifDelta is null then importoModifDelta:=0; end if;
						  /*Aggiunta delle modifiche ECONB*/
						 -- anna_economie inizio
						select tb.importo into importoModifINS
						from
						(
							select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
							from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
							siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
							siac_t_movgest_ts_det_mod moddet,
							siac_t_modifica mod, siac_r_modifica_stato rmodstato,
							siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
							siac_d_modifica_tipo tipom
						where rbil.elem_id=elemIdGestEq
						and rbil.elem_det_comp_tipo_id=impComponenteRec.compId --SIAC-7349
						and	  mov.movgest_id=rbil.movgest_id
						and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
						and   mov.movgest_anno=annoMovimento::integer
						and   mov.bil_id=bilancioId
						and   ts.movgest_id=mov.movgest_id
						and   rstato.movgest_ts_id=ts.movgest_ts_id
						and   rstato.movgest_stato_id!=movGestStatoIdAnnullato -- impegno non annullato
						and   tsdet.movgest_ts_id=ts.movgest_ts_id
						and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
					   and   tipom.mod_tipo_id=mod.mod_tipo_id
					   and   tipom.mod_tipo_code = 'ECONB'
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
					   group by ts.movgest_ts_tipo_id
					 ) tb, siac_d_movgest_ts_tipo tipo
					 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					 order by tipo.movgest_ts_tipo_code desc
					 limit 1;

					 if importoModifINS is null then 
						importoModifINS = 0;
					 end if;

					end if;		
	
			--Fix MR adeguamento sprint 5
			-- Mon restituiamo piu' al valore impegnato le modifiche provvisorie e le ECONB
           		importoModifDelta:=0;
            		importoModifINS:=0;
            --
			
			annoimpegnato:=impComponenteRec.annualita;
			elemDetCompId:=impComponenteRec.compId;
			elemdetcompdesc:=impComponenteRec.compDesc;
			elemdetcompmacrotipodesc:=impComponenteRec.compMacroTipoDesc;
			impegnatoDefinitivo:=0; -- SIAC-7349 evito di tornare null nei casi in cui non c'e' alcun impegnato sulla componente  
			impegnatoDefinitivo:=impegnatoDefinitivo+impComponenteRec.importoCurAttuale-(importoModifDelta);
			--aggiunta per ECONB
			impegnatoDefinitivo:=impegnatoDefinitivo+abs(importoModifINS);
			return next;	

	end loop;
	end if;
	end if;

	return;
 

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_impegnatodefinitivoug_comp_triennio_nostanz(integer, integer[])
    OWNER TO siac;
--SIAC-7349 fine

--SIAC-7593 inizio

--siac_dwh_impegno    
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_macro_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_macro_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_sotto_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_sotto_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_ambito_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_ambito_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fonte_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fonte_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fase_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fase_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_def_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_def_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_gest_aut', 'VARCHAR(50)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_anno', 'INTEGER');

-- siac_dwh_subimpegno
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_macro_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_macro_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_sotto_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_sotto_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_ambito_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_ambito_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fonte_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fonte_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fase_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fase_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_def_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_def_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_gest_aut', 'VARCHAR(50)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_anno', 'INTEGER');


-- fase_bil_t_gest_apertura_pluri
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_pluri', 'elem_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_pluri', 'elem_orig_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_pluri', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_pluri_id', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_pluri', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_pluri_id_1', 'elem_orig_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');


-- fase_bil_t_gest_apertura_liq_imp
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_liq_imp', 'elem_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_liq_imp', 'elem_orig_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_liq_imp', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_liq_imp_id', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_liq_imp', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_liq_imp_id_1', 'elem_orig_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');

-- fase_bil_d_elaborazione_tipo
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_d_elaborazione_tipo', 'fase_bil_elab_tipo_param', 'VARCHAR(200)');

update fase_bil_d_elaborazione_tipo tipo
set    fase_bil_elab_tipo_param='Da attribuire|parte fresca|finanziata da FPV da ROR|finanziata da FPV non ROR',
       data_modifica=now(),
       login_operazione=tipo.login_operazione||'-SIAC-7593'
where tipo.ente_proprietario_id=2
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
and   tipo.login_operazione not like '%SIAC-7593%';


update fase_bil_d_elaborazione_tipo tipo
set    fase_bil_elab_tipo_param='Da attribuire|NUOVA RICHIESTA|FPV APPLICATO|FPV APPLICATO',
       data_modifica=now(),
       login_operazione=tipo.login_operazione||'-SIAC-7593'
where tipo.ente_proprietario_id=3
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
and   tipo.login_operazione not like '%SIAC-7593%';


update fase_bil_d_elaborazione_tipo tipo
set    fase_bil_elab_tipo_param='GENERICA',
       data_modifica=now(),
       login_operazione=tipo.login_operazione||'-SIAC-7593'
where tipo.ente_proprietario_id in (4,5,10,13,14,16)
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
and   tipo.login_operazione not like '%SIAC-7593%';

-- fase_bil_t_reimputazione
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'elem_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'importo_modifica_entrata', 'numeric');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'importo_reimputato', 'numeric');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'coll_mod_entrata', 'boolean');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'coll_det_mod_entrata', 'boolean');

SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_reimputazione', 'siac_d_elem_det_comp_tipo_fase_bil_t_reimputazione_id', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');


-----
drop FUNCTION if exists fnc_fasi_bil_gest_apertura_imp_popola_puntuale
(
  enteProprietarioId     integer,
  annoBilancio           integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
);

drop function if exists  fnc_fasi_bil_gest_apertura_imp_popola
(
  enteProprietarioId     integer,
  annoBilancio           integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
);

drop  FUNCTION if exists fnc_fasi_bil_gest_apertura_liq_elabora_imp
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

drop FUNCTION if exists fnc_fasi_bil_gest_apertura_pluri_popola_puntuale
(
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop FUNCTION if exists fnc_fasi_bil_gest_apertura_pluri_popola
(
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop FUNCTION if exists fnc_fasi_bil_gest_apertura_pluri_elabora
(
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  tipocapitologest varchar,
  tipomovgest varchar,
  tipomovgestts varchar,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_imp_popola_puntuale(
  enteProprietarioId     integer,
  annoBilancio           integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;


    faseBilElabId     integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;

	faseOp            varchar(10):=null;
    liqStatoAId       INTEGER:=null;
    ordStatoAId       INTEGER:=null;
    ordTsDetATipoId   integer:=null;
    bilElemStatoANId  integer:=null;
    movGestTsTTipoId  integer:=null;
    movGestTsSTipoId  integer:=null;
    movGestTipoId     integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_LIQ_RES    CONSTANT varchar:='APE_GEST_IMP_RES';

    I_MOVGEST_TIPO     CONSTANT varchar:='I';
	MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';

    A_LIQ_STATO  CONSTANT varchar:='A';
    A_ORD_STATO  CONSTANT varchar:='A';
    A_ORD_TS_DET_TIPO CONSTANT varchar:='A';
    A_BIL_ELEM_STATO CONSTANT varchar:='AN';

    E_FASE            CONSTANT varchar:='E'; -- esercizio provvisorio
    G_FASE            CONSTANT varchar:='G'; -- gestione approvata

BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento impegni residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_LIQ_RES||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_LIQ_RES
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza fase in corso.';
    end if;

    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_LIQ_RES
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;


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


	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (E_FASE,G_FASE) then
     	raise exception ' Il bilancio deve essere in fase % o %.',E_FASE,G_FASE;
     end if;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

	 strMessaggio:='Lettura id identificativo per liqStatoA='||A_LIQ_STATO||'.';
     select stato.liq_stato_id into strict liqStatoAId
     from siac_d_liquidazione_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.liq_stato_code=A_LIQ_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     strMessaggio:='Lettura id identificativo per ordStatoA='||A_ORD_STATO||'.';
     select stato.ord_stato_id into strict ordStatoAId
     from siac_d_ordinativo_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.ord_stato_code=A_ORD_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


	 strMessaggio:='Lettura id identificativo per bilElemStatoANId='||A_BIL_ELEM_STATO||'.';
     select stato.elem_stato_id into strict bilElemStatoANId
     from siac_d_bil_elem_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.elem_stato_code=A_BIL_ELEM_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     strMessaggio:='Lettura id identificativo per ordTsDetATipo='||A_ORD_TS_DET_TIPO||'.';
     select tipo.ord_ts_det_tipo_id into strict ordTsDetATipoId
     from siac_d_ordinativo_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.ord_ts_det_tipo_code=A_ORD_STATO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTsTTipo='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTTipoId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTsSTipo='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsSTipoId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

  	 strMessaggio:='Lettura id identificativo per movGestTipo='||I_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict movGestTipoId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=I_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


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

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp impegni con dettaglio di pagamento - INIZIO.';
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

     -- impegni con pagamenti
     -- impegnato del padre - pagato di se stesso + tutti subimpegni

   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_T_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo-fnc_siac_totale_ordinativi_movgest(mov.movgest_id,null), -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,siac_r_movgest_bil_elem re
            , fase_bil_t_gest_apertura_liq_imp_puntuale pmov
       where mov.movgest_id  = pmov.movgest_id
       and   bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsTTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   exists ( select 1
                      from siac_t_movgest_ts ts1, siac_r_liquidazione_movgest rm, siac_r_liquidazione_ord ro,
                           siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                           siac_r_ordinativo_stato rsord
                      where ts1.movgest_id=mov.movgest_id
                      and   rm.movgest_ts_id=ts1.movgest_ts_id
                      and   ro.liq_id=rm.liq_id
                      and   tsord.ord_ts_id=ro.sord_id
                      and   ord.ord_id=tsord.ord_id
                      and   rsord.ord_id=ord.ord_id
                      and   rsord.ord_stato_id!=ordStatoAId
                      and   rm.data_cancellazione is null
                      and   rm.validita_fine is null
                      and   ro.data_cancellazione is null
                      and   ro.validita_fine is null
                      and   tsord.data_cancellazione is null
                      and   tsord.validita_fine is null
                      and   ord.data_cancellazione is null
                      and   ord.validita_fine is null
                      and   rsord.data_cancellazione is null
                      and   rsord.validita_fine is null)
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       and detm.movgest_ts_det_importo-fnc_siac_totale_ordinativi_movgest(mov.movgest_id,null)>0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su impegni con dettaglio di pagamento  - FINE.';
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

     -- impegni senza pagamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp impegni senza dettaglio di pagamento - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_T_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_movgest_bil_elem re
            , fase_bil_t_gest_apertura_liq_imp_puntuale pmov
       where mov.movgest_id = pmov.movgest_id
       and   bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   re.movgest_id=mov.movgest_id
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsTTipoId
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   not exists (select 1 -- non esistono ordinativi su impegno / sub
                         from siac_r_liquidazione_movgest rliq, siac_t_movgest_ts ts1,
   		                      siac_t_liquidazione l,
	                          siac_r_liquidazione_ord rliqord,
                              siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
				              siac_r_ordinativo_stato rord
                         where ts1.movgest_id=mov.movgest_id
                           and rliq.movgest_ts_id=ts1.movgest_ts_id
                           and l.liq_id=rliq.liq_id
                           and rliqord.liq_id=rliq.liq_id
					       and ts.ord_ts_id=rliqord.sord_id
					       and ord.ord_id=ts.ord_id
					       and rord.ord_id=ord.ord_id
					       and rord.ord_stato_id!=ordStatoAId
                           and rliqord.data_cancellazione is null
				           and rliqord.validita_fine is null
					       and ts.data_cancellazione is null
					       and  ts.validita_fine is null
					       and  ord.data_cancellazione is null
					       and  ord.validita_fine is null
					       and  rord.data_cancellazione is null
						   and  rord.validita_fine is null
                           and  rliq.data_cancellazione is null
						   and  rliq.validita_fine is null
                           and  ts1.data_cancellazione is null
						   and  ts1.validita_fine is null
                           and  l.data_cancellazione is null
						   and  l.validita_fine is null
                        )
       and   exists ( select 1 from siac_r_movgest_ts_stato rstato, siac_d_movgest_stato stato
                      where rstato.movgest_ts_id=movts.movgest_ts_id
                      and   stato.movgest_stato_id=rstato.movgest_stato_id
                      and   stato.movgest_stato_code not in ('A','P')
                      and   rstato.data_cancellazione is null
                      and   rstato.validita_fine is null
                    )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       order by mov.movgest_anno::integer,mov.movgest_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su impegni senza dettaglio di pagamento - FINE.';
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






     ---  subimpegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp subimpegni con dettaglio di pagamento - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_S_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo-sum(det.ord_ts_det_importo), -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_liquidazione_movgest rliq,
            siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
            siac_r_ordinativo_stato rord, siac_t_ordinativo_ts_det det, siac_r_movgest_bil_elem re
            , fase_bil_t_gest_apertura_liq_imp_puntuale pmov
       where mov.movgest_id = pmov.movgest_id
       and   bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsSTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   rliq.movgest_ts_id=movts.movgest_ts_id
       and   rliqord.liq_id=rliq.liq_id
       and   ts.ord_ts_id=rliqord.sord_id
       and   ord.ord_id=ts.ord_id
       and   rord.ord_id=ord.ord_id
       and   rord.ord_stato_id!=ordStatoAId
       and   det.ord_ts_id=ts.ord_ts_id
       and   det.ord_ts_det_tipo_id=ordTsDetATipoId
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   rliq.data_cancellazione is null
       and   rliq.validita_fine is null
       and   rliqord.data_cancellazione is null
       and   rliqord.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   ord.data_cancellazione is null
       and   ord.validita_fine is null
       and   rord.data_cancellazione is null
       and   rord.validita_fine is null
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       group by faseBilElabId,
                MOVGEST_TS_S_TIPO,
                mov.movgest_id,
                movts.movgest_ts_id,
                detm.movgest_ts_det_importo,
                mov.bil_id,
                re.elem_id,
                re.elem_det_comp_tipo_id,
                bilancioId,
   			    mov.ente_proprietario_id
       having detm.movgest_ts_det_importo-sum(det.ord_ts_det_importo)>0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer,movts.movgest_ts_code::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su subimpegni con dettaglio di pagamento  - FINE.';
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




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp subimpegni senza dettaglio di pagamento - INIZIO.';
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



   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_S_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id, -- 14.05.2020 Sofia jira siac-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_movgest_bil_elem re
            , fase_bil_t_gest_apertura_liq_imp_puntuale pmov
       where mov.movgest_id = pmov.movgest_id
       and   bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   re.movgest_id=mov.movgest_id
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsSTipoId
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   not exists (select 1
                         from siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
				              siac_r_ordinativo_stato rord,siac_r_liquidazione_movgest rliq
                         where rliq.movgest_ts_id=movts.movgest_ts_id
                           and rliqord.liq_id=rliq.liq_id
					       and ts.ord_ts_id=rliqord.sord_id
					       and ord.ord_id=ts.ord_id
					       and rord.ord_id=ord.ord_id
					       and rord.ord_stato_id!=ordStatoAId
                           and rliqord.data_cancellazione is null
				           and rliqord.validita_fine is null
					       and ts.data_cancellazione is null
					       and ts.validita_fine is null
					       and ord.data_cancellazione is null
					       and ord.validita_fine is null
					       and rord.data_cancellazione is null
						   and rord.validita_fine is null
                           and rliq.data_cancellazione is null
						   and rliq.validita_fine is null
                        )
       and   exists ( select 1 from siac_r_movgest_ts_stato rstato, siac_d_movgest_stato stato
                      where rstato.movgest_ts_id=movts.movgest_ts_id
                      and   stato.movgest_stato_id=rstato.movgest_stato_id
                      and   stato.movgest_stato_code not in ('A','P')
                      and   rstato.data_cancellazione is null
                      and   rstato.validita_fine is null
                    )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       order by mov.movgest_anno::integer,mov.movgest_numero::integer,movts.movgest_ts_code::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su subimpegni senza dettaglio di pagamento  - FINE.';
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

     --- fine subimpegni
     codResult:=null;
	 strMessaggio:='Verifica inserimento dati in fase_bil_t_gest_apertura_liq_imp.';
	 select  1 into codResult
     from fase_bil_t_gest_apertura_liq_imp liq
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.movgest_orig_id is not null
     and   liq.movgest_orig_ts_id is not null
     and   liq.elem_orig_id is not null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     if codResult is null then
     	raise exception ' Nessun inserimento effettuato.';
     end if;

	 codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp impegni/subimpegni per estremi movimento gestione prec - FINE.';
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

     --- gestione scarti per capitolo non esistente in nuovo bilancio
     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto impegni relativi a capitolo non presente in nuovo bilancio - INIZIO.';
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


     update fase_bil_t_gest_apertura_liq_imp liq
     set  scarto_code='CAP',
          scarto_desc='Capitolo non presente in bilancio di gestione corrente',
          fl_elab='X'
     from siac_t_bil_elem eprec
     where liq.fase_bil_elab_id=faseBilElabId
     and   eprec.elem_id=liq.elem_orig_id
     and   not exists (select 1
                       from siac_t_bil_elem e, siac_r_bil_elem_stato r
				       where   e.bil_id=bilancioId
					     and   e.elem_code=eprec.elem_code
					     and   e.elem_code2=eprec.elem_code2
					     and   e.elem_code3=eprec.elem_code3
					     and   e.elem_tipo_id=eprec.elem_tipo_id
					     and   r.elem_id=e.elem_id
					     and   r.elem_stato_id!=bilElemStatoANId
					     and   r.data_cancellazione is null
					     and   r.validita_fine is null
					     and   e.data_cancellazione is null
					     and   e.validita_fine is null
                      )
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;



     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto impegni capitolo non presente in nuovo bilancio - FINE.';
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

     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp identificativo elemento di bilancio corrente - INIZIO.';
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


     update fase_bil_t_gest_apertura_liq_imp liq
     set  elem_id=e.elem_id,
          elem_det_comp_tipo_id=liq.elem_orig_det_comp_tipo_id -- 14.05.2020 Sofia jira siac-7593
     from siac_t_bil_elem eprec, siac_t_bil_elem e, siac_r_bil_elem_stato r
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.fl_elab='N'
     and   eprec.elem_id=liq.elem_orig_id
     and   e.bil_id=bilancioId
     and   e.elem_code=eprec.elem_code
     and   e.elem_code2=eprec.elem_code2
     and   e.elem_code3=eprec.elem_code3
     and   e.elem_tipo_id=eprec.elem_tipo_id
     and   r.elem_id=e.elem_id
     and   r.elem_stato_id!=bilElemStatoANId
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   e.data_cancellazione is null
     and   e.validita_fine is null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;

	 select  1 into codResult
     from fase_bil_t_gest_apertura_liq_imp liq
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.fl_elab='N'
     and   liq.elem_id is null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     if codResult is not null then
     	raise exception ' Non riuscito per impegni presenti in fase_bil_t_gest_apertura_liq_imp.';
     end if;


     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp identificativo elemento di bilancio corrente - FINE.';
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


     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO IN-2.POPOLA IMPEGNI.'
     where fase.fase_bil_elab_id=faseBilElabId;


     faseBilElabRetId:=faseBilElabId;
     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_imp_popola(
  enteProprietarioId     integer,
  annoBilancio           integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;


    faseBilElabId     integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;

	faseOp            varchar(10):=null;
    liqStatoAId       INTEGER:=null;
    ordStatoAId       INTEGER:=null;
    ordTsDetATipoId   integer:=null;
    bilElemStatoANId  integer:=null;
    movGestTsTTipoId  integer:=null;
    movGestTsSTipoId  integer:=null;
    movGestTipoId     integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_LIQ_RES    CONSTANT varchar:='APE_GEST_IMP_RES';

    I_MOVGEST_TIPO     CONSTANT varchar:='I';
	MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';

    A_LIQ_STATO  CONSTANT varchar:='A';
    A_ORD_STATO  CONSTANT varchar:='A';
    A_ORD_TS_DET_TIPO CONSTANT varchar:='A';
    A_BIL_ELEM_STATO CONSTANT varchar:='AN';

    E_FASE            CONSTANT varchar:='E'; -- esercizio provvisorio
    G_FASE            CONSTANT varchar:='G'; -- gestione approvata

BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento impegni residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_LIQ_RES||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_LIQ_RES
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza fase in corso.';
    end if;

    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_LIQ_RES
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;


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


	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (E_FASE,G_FASE) then
     	raise exception ' Il bilancio deve essere in fase % o %.',E_FASE,G_FASE;
     end if;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

	 strMessaggio:='Lettura id identificativo per liqStatoA='||A_LIQ_STATO||'.';
     select stato.liq_stato_id into strict liqStatoAId
     from siac_d_liquidazione_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.liq_stato_code=A_LIQ_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     strMessaggio:='Lettura id identificativo per ordStatoA='||A_ORD_STATO||'.';
     select stato.ord_stato_id into strict ordStatoAId
     from siac_d_ordinativo_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.ord_stato_code=A_ORD_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


	 strMessaggio:='Lettura id identificativo per bilElemStatoANId='||A_BIL_ELEM_STATO||'.';
     select stato.elem_stato_id into strict bilElemStatoANId
     from siac_d_bil_elem_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.elem_stato_code=A_BIL_ELEM_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     strMessaggio:='Lettura id identificativo per ordTsDetATipo='||A_ORD_TS_DET_TIPO||'.';
     select tipo.ord_ts_det_tipo_id into strict ordTsDetATipoId
     from siac_d_ordinativo_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.ord_ts_det_tipo_code=A_ORD_STATO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTsTTipo='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTTipoId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTsSTipo='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsSTipoId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

  	 strMessaggio:='Lettura id identificativo per movGestTipo='||I_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict movGestTipoId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=I_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


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

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp impegni con dettaglio di pagamento - INIZIO.';
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

     -- impegni con pagamenti
     -- impegnato del padre - pagato di se stesso + tutti subimpegni

   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_T_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo-fnc_siac_totale_ordinativi_movgest(mov.movgest_id,null), -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsTTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   exists ( select 1
                      from siac_t_movgest_ts ts1, siac_r_liquidazione_movgest rm, siac_r_liquidazione_ord ro,
                           siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                           siac_r_ordinativo_stato rsord
                      where ts1.movgest_id=mov.movgest_id
                      and   rm.movgest_ts_id=ts1.movgest_ts_id
                      and   ro.liq_id=rm.liq_id
                      and   tsord.ord_ts_id=ro.sord_id
                      and   ord.ord_id=tsord.ord_id
                      and   rsord.ord_id=ord.ord_id
                      and   rsord.ord_stato_id!=ordStatoAId
                      and   rm.data_cancellazione is null
                      and   rm.validita_fine is null
                      and   ro.data_cancellazione is null
                      and   ro.validita_fine is null
                      and   tsord.data_cancellazione is null
                      and   tsord.validita_fine is null
                      and   ord.data_cancellazione is null
                      and   ord.validita_fine is null
                      and   rsord.data_cancellazione is null
                      and   rsord.validita_fine is null)
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       and detm.movgest_ts_det_importo-fnc_siac_totale_ordinativi_movgest(mov.movgest_id,null)>0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su impegni con dettaglio di pagamento  - FINE.';
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

     -- impegni senza pagamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp impegni senza dettaglio di pagamento - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_T_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   re.movgest_id=mov.movgest_id
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsTTipoId
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   not exists (select 1 -- non esistono ordinativi su impegno / sub
                         from siac_r_liquidazione_movgest rliq, siac_t_movgest_ts ts1,
   		                      siac_t_liquidazione l,
	                          siac_r_liquidazione_ord rliqord,
                              siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
				              siac_r_ordinativo_stato rord
                         where ts1.movgest_id=mov.movgest_id
                           and rliq.movgest_ts_id=ts1.movgest_ts_id
                           and l.liq_id=rliq.liq_id
                           and rliqord.liq_id=rliq.liq_id
					       and ts.ord_ts_id=rliqord.sord_id
					       and ord.ord_id=ts.ord_id
					       and rord.ord_id=ord.ord_id
					       and rord.ord_stato_id!=ordStatoAId
                           and rliqord.data_cancellazione is null
				           and rliqord.validita_fine is null
					       and ts.data_cancellazione is null
					       and  ts.validita_fine is null
					       and  ord.data_cancellazione is null
					       and  ord.validita_fine is null
					       and  rord.data_cancellazione is null
						   and  rord.validita_fine is null
                           and  rliq.data_cancellazione is null
						   and  rliq.validita_fine is null
                           and  ts1.data_cancellazione is null
						   and  ts1.validita_fine is null
                           and  l.data_cancellazione is null
						   and  l.validita_fine is null
                        )
       and   exists ( select 1 from siac_r_movgest_ts_stato rstato, siac_d_movgest_stato stato
                      where rstato.movgest_ts_id=movts.movgest_ts_id
                      and   stato.movgest_stato_id=rstato.movgest_stato_id
                      and   stato.movgest_stato_code not in ('A','P')
                      and   rstato.data_cancellazione is null
                      and   rstato.validita_fine is null
                    )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       order by mov.movgest_anno::integer,mov.movgest_numero::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su impegni senza dettaglio di pagamento - FINE.';
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






     ---  subimpegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp subimpegni con dettaglio di pagamento - INIZIO.';
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


   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_S_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo-sum(det.ord_ts_det_importo), -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_liquidazione_movgest rliq,
            siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
            siac_r_ordinativo_stato rord, siac_t_ordinativo_ts_det det, siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsSTipoId
       and   re.movgest_id=mov.movgest_id
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   rliq.movgest_ts_id=movts.movgest_ts_id
       and   rliqord.liq_id=rliq.liq_id
       and   ts.ord_ts_id=rliqord.sord_id
       and   ord.ord_id=ts.ord_id
       and   rord.ord_id=ord.ord_id
       and   rord.ord_stato_id!=ordStatoAId
       and   det.ord_ts_id=ts.ord_ts_id
       and   det.ord_ts_det_tipo_id=ordTsDetATipoId
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   rliq.data_cancellazione is null
       and   rliq.validita_fine is null
       and   rliqord.data_cancellazione is null
       and   rliqord.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   ord.data_cancellazione is null
       and   ord.validita_fine is null
       and   rord.data_cancellazione is null
       and   rord.validita_fine is null
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       group by faseBilElabId,
                MOVGEST_TS_S_TIPO,
                mov.movgest_id,
                movts.movgest_ts_id,
                detm.movgest_ts_det_importo,
                mov.bil_id,
                re.elem_id,
                re.elem_det_comp_tipo_id,
                bilancioId,
   			    mov.ente_proprietario_id
       having detm.movgest_ts_det_importo-sum(det.ord_ts_det_importo)>0
       order by mov.movgest_anno::integer,mov.movgest_numero::integer,movts.movgest_ts_code::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su subimpegni con dettaglio di pagamento  - FINE.';
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




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp subimpegni senza dettaglio di pagamento - INIZIO.';
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



   	 insert into fase_bil_t_gest_apertura_liq_imp
     (fase_bil_elab_id,
      movgest_ts_tipo,
      movgest_orig_id,
      movgest_orig_ts_id,
      imp_importo,
      imp_orig_importo,
      bil_orig_id,
      elem_orig_id,
      elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
      bil_id,
      ente_proprietario_id,
      login_operazione,
      validita_inizio
      )
      (select faseBilElabId,
              MOVGEST_TS_S_TIPO,
              mov.movgest_id,
              movts.movgest_ts_id,
              detm.movgest_ts_det_importo, -- imp_importo
              detm.movgest_ts_det_importo, -- imp_orig_importo
              mov.bil_id,
              re.elem_id,
              re.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
              bilancioId,
			  mov.ente_proprietario_id,
              loginOperazione,
              clock_timestamp()
       from siac_t_bil bil,siac_t_movgest mov,siac_t_movgest_ts movts,
            siac_t_movgest_ts_det detm, siac_d_movgest_ts_det_tipo tipodetm,
            siac_r_movgest_bil_elem re
       where bil.bil_id=bilancioPrecId
       and   mov.bil_id=bil.bil_id
       and   mov.movgest_tipo_id=movGestTipoId
       and   mov.movgest_anno::INTEGER<annoBilancio -- devo escludere i pluriennali
       and   re.movgest_id=mov.movgest_id
       and   movts.movgest_id=mov.movgest_id
       and   movts.movgest_ts_tipo_id=movGestTsSTipoId
       and   detm.movgest_ts_id=movts.movgest_ts_id
       and   tipodetm.movgest_ts_det_tipo_id=detm.movgest_ts_det_tipo_id
       and   tipodetm.movgest_ts_det_tipo_code='A'
       and   not exists (select 1
                         from siac_r_liquidazione_ord rliqord,siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
				              siac_r_ordinativo_stato rord,siac_r_liquidazione_movgest rliq
                         where rliq.movgest_ts_id=movts.movgest_ts_id
                           and rliqord.liq_id=rliq.liq_id
					       and ts.ord_ts_id=rliqord.sord_id
					       and ord.ord_id=ts.ord_id
					       and rord.ord_id=ord.ord_id
					       and rord.ord_stato_id!=ordStatoAId
                           and rliqord.data_cancellazione is null
				           and rliqord.validita_fine is null
					       and ts.data_cancellazione is null
					       and ts.validita_fine is null
					       and ord.data_cancellazione is null
					       and ord.validita_fine is null
					       and rord.data_cancellazione is null
						   and rord.validita_fine is null
                           and rliq.data_cancellazione is null
						   and rliq.validita_fine is null
                        )
       and   exists ( select 1 from siac_r_movgest_ts_stato rstato, siac_d_movgest_stato stato
                      where rstato.movgest_ts_id=movts.movgest_ts_id
                      and   stato.movgest_stato_id=rstato.movgest_stato_id
                      and   stato.movgest_stato_code not in ('A','P')
                      and   rstato.data_cancellazione is null
                      and   rstato.validita_fine is null
                    )
       and   mov.data_cancellazione is null
       and   mov.validita_fine is null
       and   movts.data_cancellazione is null
       and   movts.validita_fine is null
       and   detm.data_cancellazione is null
       and   detm.validita_fine is null
       and   re.data_cancellazione is null
       and   re.validita_fine is null
       order by mov.movgest_anno::integer,mov.movgest_numero::integer,movts.movgest_ts_code::integer
      );




     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_liq_imp su subimpegni senza dettaglio di pagamento  - FINE.';
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

     --- fine subimpegni
     codResult:=null;
	 strMessaggio:='Verifica inserimento dati in fase_bil_t_gest_apertura_liq_imp.';
	 select  1 into codResult
     from fase_bil_t_gest_apertura_liq_imp liq
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.movgest_orig_id is not null
     and   liq.movgest_orig_ts_id is not null
     and   liq.elem_orig_id is not null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     if codResult is null then
     	raise exception ' Nessun inserimento effettuato.';
     end if;

	 codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp impegni/subimpegni per estremi movimento gestione prec - FINE.';
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

     --- gestione scarti per capitolo non esistente in nuovo bilancio
     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto impegni relativi a capitolo non presente in nuovo bilancio - INIZIO.';
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


     update fase_bil_t_gest_apertura_liq_imp liq
     set  scarto_code='CAP',
          scarto_desc='Capitolo non presente in bilancio di gestione corrente',
          fl_elab='X'
     from siac_t_bil_elem eprec
     where liq.fase_bil_elab_id=faseBilElabId
     and   eprec.elem_id=liq.elem_orig_id
     and   not exists (select 1
                       from siac_t_bil_elem e, siac_r_bil_elem_stato r
				       where   e.bil_id=bilancioId
					     and   e.elem_code=eprec.elem_code
					     and   e.elem_code2=eprec.elem_code2
					     and   e.elem_code3=eprec.elem_code3
					     and   e.elem_tipo_id=eprec.elem_tipo_id
					     and   r.elem_id=e.elem_id
					     and   r.elem_stato_id!=bilElemStatoANId
					     and   r.data_cancellazione is null
					     and   r.validita_fine is null
					     and   e.data_cancellazione is null
					     and   e.validita_fine is null
                      )
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;



     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto impegni capitolo non presente in nuovo bilancio - FINE.';
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

     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp identificativo elemento di bilancio corrente - INIZIO.';
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

     update fase_bil_t_gest_apertura_liq_imp liq
     set  elem_id=e.elem_id,
          elem_det_comp_tipo_id=liq.elem_orig_det_comp_tipo_id -- 14.05.2020 Sofia Jira SIAC-7593
     from siac_t_bil_elem eprec, siac_t_bil_elem e, siac_r_bil_elem_stato r
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.fl_elab='N'
     and   eprec.elem_id=liq.elem_orig_id
     and   e.bil_id=bilancioId
     and   e.elem_code=eprec.elem_code
     and   e.elem_code2=eprec.elem_code2
     and   e.elem_code3=eprec.elem_code3
     and   e.elem_tipo_id=eprec.elem_tipo_id
     and   r.elem_id=e.elem_id
     and   r.elem_stato_id!=bilElemStatoANId
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   e.data_cancellazione is null
     and   e.validita_fine is null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null
     and   eprec.data_cancellazione is null
	 and   eprec.validita_fine is null;



     -- commentare
	 update fase_bil_t_gest_apertura_liq_imp liq
     set    data_cancellazione=now()
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.fl_elab='N'
     and   liq.elem_id is null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     select  1 into codResult
     from fase_bil_t_gest_apertura_liq_imp liq
     where liq.fase_bil_elab_id=faseBilElabId
     and   liq.fl_elab='N'
     and   liq.elem_id is null
     and   liq.data_cancellazione is null
     and   liq.validita_fine is null;

     if codResult is not null then
     	raise exception ' Non riuscito per impegni presenti in fase_bil_t_gest_apertura_liq_imp.';
     end if;


     codResult:=null;
     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq_imp identificativo elemento di bilancio corrente - FINE.';
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


     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO IN-2.POPOLA IMPEGNI.'
     where fase.fase_bil_elab_id=faseBilElabId;


     faseBilElabRetId:=faseBilElabId;
     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp (
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
              fase.elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
              fase.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
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
               elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
               movGestRec.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
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

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_popola_puntuale (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;
	tipoMovGestId     integer:=null;
	capUgTipoId       integer:=null;
	capEgTipoId       integer:=null;
    impTipoMovGestId  integer:=null;
    accTipoMovGestId  integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
	movGestIdRet      integer:=null;

	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
    movGestStatoAId   integer:=null;
	faseOp            varchar(10):=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';

    CAP_UG_TIPO       CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO       CONSTANT varchar:='CAP-EG';

    IMP_MOV_GEST_TIPO CONSTANT varchar:='I';
    ACC_MOV_GEST_TIPO CONSTANT varchar:='A';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

    E_FASE            CONSTANT varchar:='E'; -- esercizio provvisorio
    G_FASE            CONSTANT varchar:='G'; -- gestione approvata
BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PLURI||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_PLURI
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza fase in corso.';
    end if;


    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PLURI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;


	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict capUgTipoId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_EG_TIPO||'.';
	 select tipo.elem_tipo_id into strict capEgTipoId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_EG_TIPO
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

     strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (E_FASE, G_FASE) then
     	raise exception ' Il bilancio deve essere in fase % o %.',E_FASE,G_FASE;
     end if;

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


     strMessaggio:='Lettura id identificativo per tipoMovGest='||IMP_MOV_GEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict impTipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOV_GEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per tipoMovGest='||ACC_MOV_GEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict accTipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=ACC_MOV_GEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     strMessaggio:='Lettura identificativo per tipoMovGestTsTipoT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTipoTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsTipoS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTipoSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


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

     --- impegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per impegni - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
      elem_orig_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_det_comp_tipo_id,-- 14.05.2020 Sofia Jira SIAC-7593
              elem.elem_id,
              m.bil_id,
              'IMP', -- impegno
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=impTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoTId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per impegni - FINE.';
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

     -- subimpegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subimpegni - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
      elem_orig_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_det_comp_tipo_id,-- 14.05.2020 Sofia Jira SIAC-7593
              elem.elem_id,
              m.bil_id,
              'SIM', -- subimpegno
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=impTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoSId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer,ts.movgest_ts_code::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subimpegni - FINE.';
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


	 --- accertamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per accertamenti - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_id,
              m.bil_id,
              'ACC', -- accertamento
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=accTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoTId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per accertamenti - FINE.';
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

	-- subaccertamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subaccertamenti - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_id,
              m.bil_id,
              'SAC', -- subaccertamento
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato,
            fase_bil_t_gest_apertura_pluri_puntuale fase_punt
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=accTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoSId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
        -- fase_puntuale --
       and   fase_punt.ente_proprietario_id=enteProprietarioId
       and   fase_punt.bil_id=bilancioPrecId
       and   fase_punt.movgest_ts_id=ts.movgest_ts_id
       and   fase_punt.validita_fine is null
       and   fase_punt.data_cancellazione is null
       -- fase_puntuale --
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer,ts.movgest_ts_code::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subaccertamenti - FINE.';
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

	 -- controlli e scarti per sub per cui non inserito padre
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-1.'
     where fase.fase_bil_elab_id=faseBilElabId;


     faseBilElabRetId:=faseBilElabId;
     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_popola (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;
	tipoMovGestId     integer:=null;
	capUgTipoId       integer:=null;
	capEgTipoId       integer:=null;
    impTipoMovGestId  integer:=null;
    accTipoMovGestId  integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
	movGestIdRet      integer:=null;

	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
    movGestStatoAId   integer:=null;
	faseOp            varchar(10):=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';

    CAP_UG_TIPO       CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO       CONSTANT varchar:='CAP-EG';

    IMP_MOV_GEST_TIPO CONSTANT varchar:='I';
    ACC_MOV_GEST_TIPO CONSTANT varchar:='A';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

    E_FASE            CONSTANT varchar:='E'; -- esercizio provvisorio
    G_FASE            CONSTANT varchar:='G'; -- gestione approvata
BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PLURI||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_PLURI
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza fase in corso.';
    end if;

    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PLURI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;


	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict capUgTipoId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_EG_TIPO||'.';
	 select tipo.elem_tipo_id into strict capEgTipoId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_EG_TIPO
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

     strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (E_FASE, G_FASE) then
     	raise exception ' Il bilancio deve essere in fase % o %.',E_FASE,G_FASE;
     end if;

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


     strMessaggio:='Lettura id identificativo per tipoMovGest='||IMP_MOV_GEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict impTipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOV_GEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per tipoMovGest='||ACC_MOV_GEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict accTipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=ACC_MOV_GEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     strMessaggio:='Lettura identificativo per tipoMovGestTsTipoT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTipoTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsTipoS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict movGestTsTipoSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


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

     --- impegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per impegni - INIZIO.';
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

     -- 14.05.2020 Sofia Jira SIAC-7593
   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
      elem_orig_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_det_comp_tipo_id,-- 14.05.2020 Sofia Jira SIAC-7593
              elem.elem_id, -- 14.05.2020 Sofia Jira SIAC-7593
              m.bil_id,
              'IMP', -- impegno
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=impTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoTId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per impegni - FINE.';
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

     -- subimpegni
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subimpegni - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
      elem_orig_det_comp_tipo_id,  -- 14.05.2020 Sofia Jira SIAC-7593
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_det_comp_tipo_id,-- 14.05.2020 Sofia Jira SIAC-7593
              elem.elem_id,
              m.bil_id,
              'SIM', -- subimpegno
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=impTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoSId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer,ts.movgest_ts_code::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subimpegni - FINE.';
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


	 --- accertamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per accertamenti - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_id,
              m.bil_id,
              'ACC', -- accertamento
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=accTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoTId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per accertamenti - FINE.';
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

	-- subaccertamenti
     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subaccertamenti - INIZIO.';
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

   	 insert into fase_bil_t_gest_apertura_pluri
     (fase_bil_elab_id,
      movgest_orig_id,
	  movgest_orig_ts_id,
	  elem_orig_id,
	  bil_orig_id,
      movgest_tipo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (select faseBilElabId,
              m.movgest_id,
              ts.movgest_ts_id,
              elem.elem_id,
              m.bil_id,
              'SAC', -- subaccertamento
              clock_timestamp(),
              loginOperazione,
              m.ente_proprietario_id
       from siac_t_bil bil, siac_t_movgest m, siac_t_movgest_ts ts,
      		siac_r_movgest_bil_elem elem,siac_r_movgest_ts_stato stato
       where bil.bil_id=bilancioPrecId
       and   m.bil_id=bil.bil_id
       and   m.movgest_tipo_id=accTipoMovGestId
       and   m.movgest_anno::integer>=annoBilancio
       and   ts.movgest_id=m.movgest_id
       and   ts.movgest_ts_tipo_id=movGestTsTipoSId
	   and   elem.movgest_id=m.movgest_id
       and   stato.movgest_ts_id=ts.movgest_ts_id
       and   stato.movgest_stato_id!=movGestStatoAId
       and   m.data_cancellazione is null
       and   m.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   elem.data_cancellazione is null
       and   elem.validita_fine is null
       and   stato.data_cancellazione is null
       and   stato.validita_fine is null
       order by m.movgest_anno::integer,m.movgest_numero::integer,ts.movgest_ts_code::integer
       );

     codResult:=null;
     strMessaggio:='Inserimento fase_bil_t_gest_apertura_pluri per subaccertamenti - FINE.';
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

	 -- controlli e scarti per sub per cui non inserito padre
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-1.'
     where fase.fase_bil_elab_id=faseBilElabId;


     faseBilElabRetId:=faseBilElabId;
     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  tipocapitologest varchar,
  tipomovgest varchar,
  tipomovgestts varchar,
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

    movGestRec        record;
    aggProgressivi    record;


	movgestTsTipoDetIniz integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetAtt  integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetUtil integer; -- 29.01.2018 Sofia siac-5830

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';
	SIM_MOVGEST_TS_TIPO CONSTANT varchar:='SIM';
    SAC_MOVGEST_TS_TIPO CONSTANT varchar:='SAC';


    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

	-- 14.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;


    INIZ_MOVGEST_TS_DET_TIPO  constant varchar:='I'; -- 29.01.2018 Sofia siac-5830
    ATT_MOVGEST_TS_DET_TIPO   constant varchar:='A'; -- 29.01.2018 Sofia siac-5830
    UTI_MOVGEST_TS_DET_TIPO   constant varchar:='U'; -- 29.01.2018 Sofia siac-5830

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

    -- 14.05.2020 Sofia SIAC-7593
    elemDetCompTipoId INTEGER:=null;
BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    raise notice 'fnc_fasi_bil_gest_apertura_pluri_elabora tipoCapitoloGest=%',tipoCapitoloGest;

	if tipoMovGest=IMP_MOVGEST_TIPO then
    	 movGestTsTipoCode=SIM_MOVGEST_TS_TIPO;
    else movGestTsTipoCode=SAC_MOVGEST_TS_TIPO;
    end if;

    dataInizioVal:= clock_timestamp();
--    dataEmissione:=((annoBilancio-1)::varchar||'-12-31')::timestamp; -- da capire che data impostare come data emissione
    -- 23.08.2016 Sofia in attesa di indicazioni diverse ho deciso di impostare il primo di gennaio del nuovo anno di bilancio
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;
--    raise notice 'fasbilElabId %',faseBilElabId;
	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora tipoMovGest='||tipoMovGest||' minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
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
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_pluri.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_pluri fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna movimento da creare.';
    end if;


    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_pluri].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_pluri_id) into maxId
        from fase_bil_t_gest_apertura_pluri fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null;
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;


     strMessaggio:='Lettura id identificativo per tipo capitolo='||tipoCapitoloGest||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=tipoCapitoloGest
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

     -- per I,A
     strMessaggio:='Lettura id identificativo per tipoMovGest='||tipoMovGest||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=tipoMovGest
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

     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
          movGestTsTipoId:=tipoMovGestTsTId;
     else movGestTsTipoId:=tipoMovGestTsSId;
     end if;

     if movGestTsTipoId is null then
      strMessaggio:='Lettura identificativo per tipoMovGestTs='||tipoMovGestTs||'.';
      select tipo.movgest_ts_tipo_id into strict movGestTsTipoId
      from siac_d_movgest_ts_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.movgest_ts_tipo_code=tipoMovGestTs
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null;
     end if;


	 -- 14.02.2017 Sofia SIAC-4425
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;
     end if;

	 -- 29.01.2018 Sofia siac-5830
     strMessaggio:='Lettura identificativo per tipo importo='||INIZ_MOVGEST_TS_DET_TIPO||'.';
     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetIniz
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=INIZ_MOVGEST_TS_DET_TIPO;

     strMessaggio:='Lettura identificativo per tipo importo='||ATT_MOVGEST_TS_DET_TIPO||'.';

     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetAtt
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=ATT_MOVGEST_TS_DET_TIPO;

--	 if tipoMovGest=ACC_MOVGEST_TIPO then
     	 strMessaggio:='Lettura identificativo per tipo importo='||UTI_MOVGEST_TS_DET_TIPO||'.';
		 select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetUtil
    	 from siac_d_movgest_ts_det_tipo tipo
	     where tipo.ente_proprietario_id=enteProprietarioId
    	 and   tipo.movgest_ts_det_tipo_code=UTI_MOVGEST_TS_DET_TIPO;
  --   end if;
     -- 29.01.2018 Sofia siac-5830

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

     -- se impegno-accertamento verifico che i relativi capitoli siano presenti sul nuovo Bilancio
     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. INIZIO.';
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

        update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='IMAC1',
            scarto_desc='Movimento impegno/accertamento pluriennale privo di capitolo nel nuovo bilancio'
      	from siac_t_bil_elem elem
      	where fase.fase_bil_elab_id=faseBilElabId
      	and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      	and   fase.movgest_tipo=movGestTsTipoCode
     	and   fase.fl_elab='N'
        and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
     	and   elem.ente_proprietario_id=fase.ente_proprietario_id
        and   elem.elem_id=fase.elem_orig_id
    	and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
     	and   elem.data_cancellazione is null
     	and   elem.validita_fine is null
        and   not exists (select 1 from siac_t_bil_elem elemnew
                          where elemnew.ente_proprietario_id=elem.ente_proprietario_id
                          and   elemnew.elem_tipo_id=elem.elem_tipo_id
                          and   elemnew.bil_id=bilancioId
                          and   elemnew.elem_code=elem.elem_code
                          and   elemnew.elem_code2=elem.elem_code2
                          and   elemnew.elem_code3=elem.elem_code3
                          and   elemnew.data_cancellazione is null
                          and   elemnew.validita_fine is null
                         );


        strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. FINE.';
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

     end if;
     -- se sub, verifico prima se i relativi padri sono stati elaborati e creati
     -- se non sono stati ribaltati scarto  i relativi sub per escluderli da elaborazione

     if tipoMovGestTs=MOVGEST_TS_S_TIPO then
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. INIZIO.';
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

      update fase_bil_t_gest_apertura_pluri fase
      set fl_elab='X',
          scarto_code='SUB1',
          scarto_desc='Movimento sub impegno/accertamento pluriennale privo di impegno/accertamento pluri nel nuovo bilancio'
      from siac_t_movgest mprec
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   fase.movgest_tipo=movGestTsTipoCode
      and   fase.fl_elab='N'
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   mprec.ente_proprietario_id=fase.ente_proprietario_id
      and   mprec.movgest_id=fase.movgest_orig_id
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   mprec.data_cancellazione is null
      and   mprec.validita_fine is null
      and   not exists (select 1 from siac_t_movgest mnew
                        where mnew.ente_proprietario_id=mprec.ente_proprietario_id
                        and   mnew.movgest_tipo_id=mprec.movgest_tipo_id
                        and   mnew.bil_id=bilancioId
                        and   mnew.movgest_anno=mprec.movgest_anno
                        and   mnew.movgest_numero=mprec.movgest_numero
                        and   mnew.data_cancellazione is null
                        and   mnew.validita_fine is null
                        );
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. FINE.';
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

     end if;

     strMessaggio:='Inizio ciclo per tipoMovGest='||tipoMovGest||' tipoMovGestTs='||tipoMovGestTs||'.';
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


     for movGestRec in
     (select tipo.movgest_tipo_code,
     		 m.*,
             tstipo.movgest_ts_tipo_code,
             ts.*,
             fase.fase_bil_gest_ape_pluri_id,
             fase.movgest_orig_id,
             fase.movgest_orig_ts_id,
             fase.elem_orig_id,
             mpadre.movgest_id movgest_id_new,
             tspadre.movgest_ts_id movgest_ts_id_padre_new
      from  fase_bil_t_gest_apertura_pluri fase
             join siac_t_movgest m
               left outer join
               ( siac_t_movgest mpadre join  siac_t_movgest_ts tspadre
                   on (tspadre.movgest_id=mpadre.movgest_id
                   and tspadre.movgest_ts_tipo_id=tipoMovGestTsTId
                   and tspadre.data_cancellazione is null
                   and tspadre.validita_fine is null)
                )
                on (mpadre.movgest_anno=m.movgest_anno
                and mpadre.movgest_numero=m.movgest_numero
                and mpadre.bil_id=bilancioId
                and mpadre.ente_proprietario_id=m.ente_proprietario_id
                and mpadre.movgest_tipo_id = tipoMovGestId
                and mpadre.data_cancellazione is null
                and mpadre.validita_fine is null)
             on   ( m.ente_proprietario_id=fase.ente_proprietario_id  and   m.movgest_id=fase.movgest_orig_id),
            siac_d_movgest_tipo tipo,
            siac_t_movgest_ts ts,
            siac_d_movgest_ts_tipo tstipo
      where fase.fase_bil_elab_id=faseBilElabId
          and   tipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tipo.movgest_tipo_code=tipoMovGest
          and   tstipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tstipo.movgest_ts_tipo_code=tipoMovGestTs
          and   m.ente_proprietario_id=fase.ente_proprietario_id
          and   m.movgest_id=fase.movgest_orig_id
          and   m.movgest_tipo_id=tipo.movgest_tipo_id
          and   ts.ente_proprietario_id=fase.ente_proprietario_id
          and   ts.movgest_ts_id=fase.movgest_orig_ts_id
          and   ts.movgest_ts_tipo_id=tstipo.movgest_ts_tipo_id
          and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
          and   fase.fl_elab='N'
          and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          order by fase_bil_gest_ape_pluri_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        codResult:=null;
		elemNewId:=null;

		-- 14.05.2020 Sofia SIAC-7593
        elemDetCompTipoId:=null;

        strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
         raise notice 'strMessaggio=%  movGestRec.movgest_id_new=%', strMessaggio, movGestRec.movgest_id_new;
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
        if movGestRec.movgest_id_new is null then
      	 strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                       ' anno='||movGestRec.movgest_anno||
                       ' numero='||movGestRec.movgest_numero||' [siac_t_movgest].';
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
         values
         (movGestRec.movgest_anno,
		  movGestRec.movgest_numero,
		  movGestRec.movgest_desc,
		  movGestRec.movgest_tipo_id,
		  bilancioId,
		  dataInizioVal,
	      enteProprietarioId,
	      loginOperazione,
	      movGestRec.parere_finanziario,
	      movGestRec.parere_finanziario_data_modifica,
	      movGestRec.parere_finanziario_login_operazione
         )
         returning movgest_id into movGestIdRet;
         if movGestIdRet is null then
           strMessaggioTemp:=strMessaggio;
           codResult:=-1;
         end if;
			raise notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movGestIdRet;
		 if codResult is null then
         strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';

         raise notice 'strMessaggio=%',strMessaggio;
         -- 14.05.2020 Sofia SIAC-7593
         --select  new.elem_id into elemNewId
         select  new.elem_id , r.elem_det_comp_tipo_id into  elemNewId,elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
         from siac_r_movgest_bil_elem r,
              siac_t_bil_elem prec, siac_t_bil_elem new
         where r.movgest_id=movGestRec.movgest_orig_id
         and   prec.elem_id=r.elem_id
         and   new.elem_code=prec.elem_code
         and   new.elem_code2=prec.elem_code2
         and   new.elem_code3=prec.elem_code3
         and   prec.elem_tipo_id=new.elem_tipo_id
         and   prec.bil_id=bilancioPrecId
         and   new.bil_id=bilancioId
         and   r.data_cancellazione is null
         and   r.validita_fine is null
         and   prec.data_cancellazione is null
         and   prec.validita_fine is null
         and   new.data_cancellazione is null
         and   new.validita_fine is null;
         if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
         end if;
		 raise notice 'elemNewId=%',elemNewId;
		 if codResult is null then
          	  strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
             	            ' anno='||movGestRec.movgest_anno||
                 	        ' numero='||movGestRec.movgest_numero||' [siac_r_movgest_bil_elem]';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
               elem_Det_comp_tipo_id, -- 14.05.2020 Sofia SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   elemNewId,
               elemDetCompTipoId, -- 14.05.2020 Sofia SIAC-7593
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
        end if;
      else
        movGestIdRet:=movGestRec.movgest_id_new;
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';
        -- 14.05.2020 Sofia SIAC-7593
        --select  r.elem_id into elemNewId
        select  r.elem_id,r.elem_det_comp_tipo_id into elemNewId, elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
        from siac_r_movgest_bil_elem r
        where r.movgest_id=movGestIdRet
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;
      end if;


      if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts].';
		raise notice 'strMessaggio=% ',strMessaggio;
/*        dataEmissione:=( (2018::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;*/

        -- 21.02.2019 Sofia SIAC-6683
        dataEmissione:=( (annoBilancio::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;
        raise notice 'dataEmissione=% ',dataEmissione;

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
        values
        ( movGestRec.movgest_ts_code,
          movGestRec.movgest_ts_desc,
          movGestIdRet,    -- inserito se I/A, per SUB ricavato
          movGestRec.movgest_ts_tipo_id,
          movGestRec.movgest_ts_id_padre_new,  -- valorizzato se SUB
          movGestRec.movgest_ts_scadenza_data,
          movGestRec.ordine,
          movGestRec.livello,
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataInizioVal else dataEmissione end), -- 25.11.2016 Sofia
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataEmissione else dataInizioVal end), -- 25.11.2016 Sofia
--          dataEmissione, -- 12.04.2017 Sofia
          dataEmissione,   -- 09.02.2018 Sofia
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          movGestRec.siope_tipo_debito_id,
		  movGestRec.siope_assenza_motivazione_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;
        raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;
       -- siac_r_liquidazione_movgest --> x pluriennali non dovrebbe esserci legame e andrebbe ricreato cmq con il ribaltamento delle liq
       -- siac_r_ordinativo_ts_movgest_ts --> x pluriennali non dovrebbe esistere legame in ogni caso non deve essere  ribaltato
       -- siac_r_movgest_ts --> legame da creare alla conclusione del ribaltamento dei pluriennali e dei residui

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
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
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        -- 29.01.2018 Sofia siac-5830 - insert sostituita con le tre successive


        /*insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );*/
        --returning movgest_ts_det_id into  codResult;

        -- 29.01.2018 Sofia siac-5830 - iniziale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetIniz,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - attuale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - utilizzabile = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetUtil,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
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
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
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
--        returning movgest_classif_id into  codResult;

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;


        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning bil_elem_attr_id into  codResult;

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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

        /*select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        --returning movgest_atto_amm_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
         end if;
       end if;*/

       -- se movimento provvisorio atto_amm potrebbe non esserci
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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning movgest_ts_sog_id into  codResult;

        /*select 1 into codResult
        from siac_r_movgest_ts_sog det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
          and   classe.data_cancellazione is null
          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning soggetto_classe_id into  codResult;

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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- 03.05.2019 Sofia siac-6255
       if codResult is null then
         -- siac_r_movgest_ts_programma
         if faseOp=G_FASE then
          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
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
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
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
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );
          --returning movgest_ts_programma_id into  codResult;
          /*select 1 into codResult
          from siac_r_movgest_ts_programma det
          where det.movgest_ts_id=movGestTsIdRet
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   det.login_operazione=loginOperazione;*/

		  -- 03.05.2019 Sofia siac-6255
          /*
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

          if codResult is not null then
           codResult:=-1;
           strMessaggioTemp:=strMessaggio;
          else codResult:=null;
          end if;*/

          -- siac_r_movgest_ts_cronop_elem
          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
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
            and   rsc.validita_fine is null;

          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
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
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
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
            and   cnew.bil_id=bilancioId
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
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
            and   rsc.validita_fine is null;
         end if;
       end if;
       -- 03.05.2019 Sofia siac-6255

       -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning mut_voce_movgest_id into  codResult;

        /*select 1 into codResult
        from siac_r_mutuo_voce_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa economale - da non ricreare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning gstmovgest_id into  codResult;

    /*    select 1 into codResult
        from siac_r_giustificativo_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning subdoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_cartacont_det_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/


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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_causale_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning caus_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_causale_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_fondo_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning liq_movgest_id into  codResult;

       /* select 1 into codResult
        from siac_r_fondo_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_richiesta_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning riceconsog_id into  codResult;

       /* select 1 into codResult
        from siac_r_richiesta_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_subdoc_movgest_ts].';

        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

       /* select 1 into codResult
        from siac_r_subdoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
        --returning predoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_predoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- cancellazione logica relazioni anno precedente
       -- siac_r_cartacont_det_movgest_ts
/*  non si gestisce in seguito ad indicazioni con Annalina
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' . Cancellazione siac_r_cartacont_det_movgest_ts anno bilancio precedente.';

        update siac_r_cartacont_det_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_cartacont_det_movgest_ts r,	siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if codResult is not null then
        	 strMessaggioTemp:=strMessaggio;
        	 codResult:=-1;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null and tipoMovGest=IMP_MOVGEST_TIPO then
		strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
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
       -- aggiornamento fase_bil_t_gest_apertura_pluri per scarto
	   if codResult=-1 then
       	/*if movGestRec.movgest_id_new is null then
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        end if; spostato sotto */

        if movGestTsIdRet is not null then
         -- siac_t_movgest_ts
 	    /*strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet; spostato sotto */

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
/*
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
         strMessaggio:=strMessaggioTemp||
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
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet;*/
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

		 -- 17.06.2019 Sofia SIAC-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if movGestRec.movgest_id_new is null then
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
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';*/
	    strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='PLUR1',
            scarto_desc='Movimento impegno/accertamento sub  pluriennale non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

		continue;
       end if;

	   -- annullamento relazioni movimenti precedenti
       -- siac_r_subdoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             --strMessaggioTemp:=strMessaggio;
             raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
--             strMessaggioTemp:=strMessaggio;
               raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'. Aggiornamento fase_bil_t_gest_apertura_pluri per fine elaborazione.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='S',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet,
            elem_id=elemNewId,
            elem_Det_comp_tipo_id=elemDetCompTipoId, -- 14.05.2020 Sofia Jira SIAC-7593
            bil_id=bilancioId
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

       strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
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


     -- aggiornamento progressivi
	 if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	 strMessaggio:='Aggiornamento progressivi.';
		 select * into aggProgressivi
   		 from fnc_aggiorna_progressivi(enteProprietarioId, tipoMovGest, loginOperazione);
	     if aggProgressivi.codresult=-1 then
			RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
     	 end if;
     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
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
        and   mov.movgest_anno::integer>annoBilancio
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
        -- -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
		update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
		and   mov.movgest_anno::integer>annoBilancio
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
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atto amministrativo antecedente.';
        update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts,
		     siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::INTEGER=annoBilancio
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

     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-2.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
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
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

drop FUNCTION if exists fnc_siac_riaccertamento_reimp
(
	mod_id_in integer,
	login_operazione_in character varying,
	tipo_operazione_in character varying
);

drop function if exists fnc_fasi_bil_gest_reimputa_vincoli_acc
(
  enteproprietarioid integer,
  annobilancio integer,
  faseBilElabId integer,
  annoImpegnoRiacc integer,   -- annoImpegno riaccertato
  movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
  avavRiaccImpId   integer,        -- avav_id nuovo
  importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
  faseBilElabReAccId integer, -- faseId di elaborazione riaccertmaento Acc
  tipoMovGestAccId integer,   -- tipoMovGestId Accertamenti
  movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
  loginoperazione varchar,
  dataelaborazione timestamp,
  out numeroVincoliCreati integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists fnc_fasi_bil_gest_reimputa_vincoli
(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	dataelaborazione timestamp without time zone,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
);

drop FUNCTION if exists fnc_fasi_bil_gest_reimputa_popola
(
	p_fasebilelabid integer,
	p_enteproprietarioid integer,
	p_annobilancio integer,
	p_loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
);

drop FUNCTION if exists fnc_fasi_bil_gest_reimputa_popola
(
	p_fasebilelabid integer,
	p_enteproprietarioid integer,
	p_annobilancio integer,
	p_loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
    componenteFittiziaId integer,
    componenteFrescoId integer,
    componenteFPVId integer,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
);

drop function if exists fnc_fasi_bil_gest_reimputa_elabora
(
	p_fasebilelabid integer,
	enteproprietarioid integer,
	annobilancio integer,
	impostaprovvedimento boolean,
	loginoperazione character varying,
	dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
);

drop FUNCTION if exists fnc_fasi_bil_gest_reimputa_sing
(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
	impostaprovvedimento character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
);

drop FUNCTION if exists fnc_fasi_bil_gest_reimputa_sing
(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
    componenteDef character varying,  -- 05.06.2020 Sofia Jira siac-7593
	impostaprovvedimento character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
);

drop FUNCTION if exists fnc_fasi_bil_gest_reimputa
(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	impostaprovvedimento character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
);


CREATE OR REPLACE FUNCTION fnc_siac_riaccertamento_reimp
(
	mod_id_in integer,
	login_operazione_in character varying,
	tipo_operazione_in character varying
)
RETURNS varchar
AS $body$

DECLARE
importo_mod_da_scalare numeric:=null;
importo_delta_vincolo numeric:=null;
ente_proprietario_id_in integer;
rec record;

esito varchar(10);

 strMessaggio varchar(1000) := null;

cur CURSOR(par_in integer) FOR
select query.tipomod,
	   query.mod_id,
       query.movgest_ts_r_id,
       query.movgest_ts_importo,
       query.tipoordinamento
from
(
--avav
SELECT 'avav' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo,
case when n.avav_tipo_code='FPVSC' then 1
	 when n.avav_tipo_code='FPVCC' then 1 when n.avav_tipo_code='AAM' then 2 else 3 end
		as tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_t_avanzovincolo l, siac_d_movgest_ts_tipo m,siac_d_avanzovincolo_tipo n,
siac_r_movgest_ts i
WHERE
a.mod_id=par_in--mod_id_in
 and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
c.mtdm_reimputazione_flag=true and
c.movgest_ts_det_importo<0 and
i.movgest_ts_b_id=f.movgest_ts_id and
i.movgest_ts_importo>0 and -- con importo ancora da aggiornare
n.avav_tipo_id=l.avav_tipo_id and
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.avav_id=i.avav_id and
i.movgest_ts_importo> -- vincoli impegno FPV/AAM che non sono gia' stati aggiornati da on-line su mod.spesa
(
select coalesce(sum(rvinc.importo_delta ),0) importo_delta
from siac_r_modifica_vincolo rvinc
where rvinc.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc.mod_id=a.mod_id
and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
) and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null and
n.data_cancellazione is null
union
-- imp acc
SELECT
'impacc' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo,
4 tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_r_movgest_ts i,
siac_t_movgest_ts l, siac_d_movgest_ts_tipo m
WHERE
a.mod_id=par_in--mod_id_in
and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
c.mtdm_reimputazione_flag=true and
c.movgest_ts_det_importo<0 and
i.movgest_ts_b_id=f.movgest_ts_id and
i.movgest_ts_importo>0 and -- con importo ancora da aggiornare
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.movgest_ts_id=i.movgest_ts_a_id and
i.movgest_ts_importo>
(
select coalesce(sum(vinc.importo_delta),0)
FROM
(
--  vincoli impegno accertamento che non sono gia' stati aggiornati da on-line su mod.spesa (A)
-- (A)
(
select coalesce(sum(rvinc.importo_delta),0) importo_delta
from siac_r_modifica_vincolo rvinc
where rvinc.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc.mod_id=a.mod_id
and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
)
union
(
select coalesce(sum(rvinc_mod.importo_delta),0) importo_delta
from   siac_r_modifica_vincolo rvinc_mod,
       siac_r_modifica_stato rs_mod_acc,
       siac_t_movgest_ts_det_mod det_mod_acc,
	   siac_r_movgest_ts_det_mod rmod_acc

where rvinc_mod.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc_mod.modvinc_tipo_operazione='INSERIMENTO'
and   rs_mod_acc.mod_id=rvinc_mod.mod_id
and   det_mod_acc.mod_stato_r_id=rs_mod_acc.mod_stato_r_id
and   det_mod_acc.movgest_ts_id=i.movgest_ts_a_id
and   det_mod_acc.mtdm_reimputazione_flag=true
and   det_mod_acc.movgest_ts_det_importo<0
and   rmod_acc.movgest_ts_det_mod_entrata_id=det_mod_acc.movgest_ts_det_mod_id
and   rmod_acc.movgest_ts_det_mod_spesa_id=c.movgest_ts_det_mod_id
and   rs_mod_acc.mod_stato_id=d.mod_stato_id
and   rvinc_mod.data_cancellazione is null
and   rvinc_mod.validita_fine is null
and   rs_mod_acc.data_cancellazione is null
and   rs_mod_acc.validita_fine is null
and   det_mod_acc.data_cancellazione is null
and   det_mod_acc.validita_fine is null
)
) vinc
) and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null
) query
order
by 5 desc,2 asc,4 desc,
-- 21.07.2020 Sofia aggiunto ultimo ord. per coerenza rispetto codice java per calcolo
-- campo pending in elenco vincoli
3 desc;



begin

strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Inizio.';
raise notice '%',strMessaggio;

esito:='oknodata'::varchar;

strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_mod_da_calare.';
raise notice '%',strMessaggio;

-- calcolo importo della modifica  a parametro
SELECT abs(det_mod.movgest_ts_det_importo), det_mod.ente_proprietario_id
       into importo_mod_da_scalare, ente_proprietario_id_in
FROM siac_t_modifica mod,
     siac_r_modifica_stato rs_mod,
     siac_d_modifica_stato stato_mod,
     siac_t_movgest_ts ts,
     siac_t_movgest mov,
     siac_d_movgest_tipo tipo_mov,
     siac_t_movgest_ts_det_mod det_mod
WHERE mod.mod_id = mod_id_in
and   rs_mod.mod_id = mod.mod_id
and   det_mod.mod_stato_r_id = rs_mod.mod_stato_r_id
and   stato_mod.mod_stato_id = rs_mod.mod_stato_id
and   stato_mod.mod_stato_code = 'V'
and   ts.movgest_ts_id = det_mod.movgest_ts_id
and   mov.movgest_id = ts.movgest_id
and   tipo_mov.movgest_tipo_id = mov.movgest_tipo_id
and   tipo_mov.movgest_tipo_code = 'I'
and   det_mod.mtdm_reimputazione_flag=true
and   det_mod.movgest_ts_det_importo<0
and   now() BETWEEN rs_mod.validita_inizio
and   COALESCE(rs_mod.validita_fine, now())
and   mod.data_cancellazione IS NULL
and   rs_mod.data_cancellazione IS NULL
and   det_mod.data_cancellazione IS NULL
and   ts.data_cancellazione IS NULL
and   mov.data_cancellazione is null;

strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_mod_da_calare='||coalesce(importo_mod_da_scalare,0)::varchar||'.';
raise notice '%',strMessaggio;

-- calcolo dei delta sui vincoli impegno adeguati con la modifica  a parametro
if importo_mod_da_scalare is not null and
   importo_mod_da_scalare>0 then
   strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su impegno.';
   raise notice '%',strMessaggio;

   select sum(abs(rvinc.importo_delta)) into importo_delta_vincolo
   from siac_r_modifica_vincolo rvinc
   where rvinc.mod_id=mod_id_in
   and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
   and   rvinc.data_cancellazione is null
   and   rvinc.validita_fine is null;
   strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su imp ='||coalesce(importo_delta_vincolo,0)::varchar||'.';
   raise notice '%',strMessaggio;
   if importo_delta_vincolo is not null then
   		importo_mod_da_scalare:=importo_mod_da_scalare-importo_delta_vincolo;
   end if;

end if;

-- calcolo dei delta sui vincoli di accertamento legati sia (vincolo o mod_entrata)
-- a impegno della modifica a parametro
if importo_mod_da_scalare is not null and
   importo_mod_da_scalare>0 then

  strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su accert.';
  raise notice '%',strMessaggio;
  importo_delta_vincolo:=null;
  select sum(abs(rvinc_mod.importo_delta)) into importo_delta_vincolo
  from siac_r_modifica_stato rs_spesa,siac_d_modifica_stato stato_mod_spesa,
       siac_t_movgest_ts_det_mod det_mod_spesa,
       siac_r_movgest_ts_det_mod rmod_acc, siac_t_movgest_ts_det_mod det_mod_acc,
       siac_r_modifica_vincolo rvinc_mod,siac_r_movgest_ts rvinc,
       siac_r_modifica_stato rs_mod_acc
  where rs_spesa.mod_id=mod_id_in
  and   stato_mod_spesa.mod_stato_id=rs_spesa.mod_stato_id
  and   stato_mod_spesa.mod_Stato_code='V'
  and   det_mod_spesa.mod_stato_r_id=rs_spesa.mod_stato_r_id
  and   rmod_acc.movgest_ts_det_mod_spesa_id=det_mod_spesa.movgest_ts_det_mod_id
  and   det_mod_acc.movgest_ts_det_mod_id=rmod_acc.movgest_ts_det_mod_entrata_id
  and   det_mod_acc.mtdm_reimputazione_flag=true
  and   det_mod_acc.movgest_ts_det_importo<0
  and   rs_mod_acc.mod_stato_r_id=det_mod_acc.mod_stato_r_id
  and   rs_mod_acc.mod_Stato_id=stato_mod_spesa.mod_stato_id
  and   rvinc.movgest_ts_b_id=det_mod_spesa.movgest_ts_id
  and   rvinc.movgest_ts_a_id=det_mod_acc.movgest_ts_id
  and   rvinc_mod.movgest_ts_r_id=rvinc.movgest_ts_r_id
  and   rvinc_mod.mod_id=rs_mod_acc.mod_id
  and   rvinc_mod.modvinc_tipo_operazione='INSERIMENTO'
  and   rs_spesa.data_cancellazione is null
  and   rs_spesa.validita_fine is null
  and   det_mod_spesa.data_cancellazione is null
  and   det_mod_spesa.validita_fine is null
  and   rmod_acc.data_cancellazione is null
  and   rmod_acc.validita_fine is null
  and   det_mod_acc.data_cancellazione is null
  and   det_mod_acc.validita_fine is null
  and   rvinc_mod.data_cancellazione is null
  and   rvinc_mod.validita_fine is null
  and   rvinc.data_cancellazione is null
  and   rvinc.validita_fine is null
  and   rs_mod_acc.data_cancellazione is null
  and   rs_mod_acc.validita_fine is null;
  strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su accert='||coalesce(importo_delta_vincolo,0)::varchar||'.';
  raise notice '%',strMessaggio;
  if importo_delta_vincolo is not null then
   		importo_mod_da_scalare:=importo_mod_da_scalare-importo_delta_vincolo;
   end if;
end if;


strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. importo_mod_da_scalare='||coalesce(importo_mod_da_scalare,0)::varchar||'.';
raise notice '%',strMessaggio;

if importo_mod_da_scalare>0 then
strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Inizio loop di aggiornamento.';
raise notice '%',strMessaggio;
for rec in cur(mod_id_in) loop
    if rec.movgest_ts_importo is not null and importo_mod_da_scalare>0 then
        if rec.movgest_ts_importo - importo_mod_da_scalare <=0 then

          esito:='ok';
          update siac_r_movgest_ts
          set movgest_ts_importo = 0,
              login_operazione = login_operazione_in,
              data_modifica = clock_timestamp()
          where movgest_ts_r_id = rec.movgest_ts_r_id;

          insert into siac_r_modifica_vincolo
          (mod_id, movgest_ts_r_id,
           modvinc_tipo_operazione, importo_delta, validita_inizio, ente_proprietario_id,
           login_operazione)
          values
          (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO', -rec.movgest_ts_importo,
           clock_timestamp(), ente_proprietario_id_in, login_operazione_in || ' - ' ||
            'fnc_siac_riccertamento_reimp');

          importo_mod_da_scalare:= importo_mod_da_scalare - rec.movgest_ts_importo;

        elsif rec.movgest_ts_importo - importo_mod_da_scalare > 0 then
          esito:='ok';
          update siac_r_movgest_ts
          set    movgest_ts_importo = movgest_ts_importo - importo_mod_da_scalare,
                 login_operazione=login_operazione_in,
                 data_modifica=clock_timestamp()
          where movgest_ts_r_id=rec.movgest_ts_r_id;

          insert into siac_r_modifica_vincolo
          (mod_id,movgest_ts_r_id,modvinc_tipo_operazione,
           importo_delta,validita_inizio,ente_proprietario_id,login_operazione )
          values
          (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO',-importo_mod_da_scalare,clock_timestamp(),
           ente_proprietario_id_in,login_operazione_in||' - '||'fnc_siac_riccertamento_reimp' );

          importo_mod_da_scalare:= importo_mod_da_scalare - importo_mod_da_scalare;

        end if;
    end if;
end loop;

end if;

strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Fine esito='||esito||'.';
return esito;

EXCEPTION
WHEN others THEN
  esito:='ko';
  strMessaggio:='Aggiornamento vincoli da reimputazione - fnc_siac_riaccertamento_reimp - mod_id='
             ||mod_id_in::varchar||'. Fine esito='||esito||'-  '||SQLSTATE||'-'||SQLERRM||'.';
  RAISE NOTICE '%',strMessaggio;
RETURN esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

create or replace function fnc_fasi_bil_gest_reimputa_vincoli_acc
(
  enteproprietarioid integer,
  annobilancio integer,
  faseBilElabId integer,
  annoImpegnoRiacc integer,   -- annoImpegno riaccertato
  movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
  avavRiaccImpId   integer,        -- avav_id nuovo
  importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
  faseBilElabReAccId integer, -- faseId di elaborazione riaccertmaento Acc
  tipoMovGestAccId integer,   -- tipoMovGestId Accertamenti
  movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
  loginoperazione varchar,
  dataelaborazione timestamp,
  out numeroVincoliCreati integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    daVincolare numeric:=0;
    importoVinc numeric:=0;
    totVincolato numeric:=0;

    daCancellare BOOLEAN:=false;
    movGestRec record;

    numeroVinc   integer:=0;
BEGIN

    codiceRisultato:=null;
    messaggioRisultato:=null;
    numeroVincoliCreati:=0;

	strMessaggioFinale:='Reimputazione vincoli su accertamento riacc. Anno bilancio='
                     ||annoBilancio::varchar
                     ||' per impegno riacc movgest_ts_id='||movgestTsImpNewId::varchar
                     ||' per avav_id='||avavRiaccImpId::varchar
                     ||' per importo vincolo='||importoVincoloRiaccertato::varchar||'.';

    raise notice 'strMessaggioFinale=%',strMessaggioFinale;
    strMessaggio:='Inizio elaborazione.';
    insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
	values
    (faseBilElabId,strMessaggioFinale||' - INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	returning fase_bil_elab_log_id into codResult;

	if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	end if;

    daVincolare:=importoVincoloRiaccertato;
	for movGestRec in
	(
	 with
	 accPrec as
	 (-- accertamento vincolato in annoBilancio-1
	  select mov.movgest_anno::integer anno_accertamento,
  			 mov.movgest_numero::integer numero_accertamento,
	         (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
    	     mov.movgest_id, ts.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
    	   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
	  where ts.movgest_ts_id=movgestTsAccPrecId
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   mov.movgest_id=ts.movgest_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	 ),
 	 accCurRiacc as
	 (-- accertamenti riaccertati per accPrec in annoBilancio
	  select mov.movgest_anno::integer anno_accertamento,
    	     mov.movgest_numero::integer numero_accertamento,
	 	     (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
		     mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
   		   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase,siac_d_movgest_stato stato,
           siac_t_bil bil,siac_t_periodo per
	  where bil.ente_proprietario_id=enteProprietarioId
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=annoBilancio
      and   mov.bil_id=bil.bil_id
	  and   mov.movgest_tipo_id=tipoMovGestAccId
	  and   ts.movgest_id=mov.movgest_id
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
	  and   fase.fasebilelabid=faseBilElabReAccId
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
	  and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
	  and   mov.movgest_anno::integer<=annoImpegnoRiacc
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	),
	accUtilizzabile as
	(-- utlizzabile per accertamento
	 select det.movgest_ts_id, det.movgest_ts_det_importo importo_utilizzabile
	 from siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
	 where tipo.ente_proprietario_id=enteProprietarioId
	 and   tipo.movgest_ts_det_tipo_code='U'
	 and   det.movgest_ts_det_tipo_id= tipo.movgest_ts_det_tipo_id
	 and   det.data_cancellazione is null
	 and   det.validita_fine is null
	),
	vincolato as
	(-- vincolato per accertamento
	 select r.movgest_ts_a_id, sum(r.movgest_ts_importo) totale_vincolato
     from siac_r_movgest_ts r
	 where r.ente_proprietario_id=enteProprietarioId
	 and   r.data_cancellazione is null
	 and   r.validita_fine is null
     and   r.movgest_ts_a_id is not null
	 group by r.movgest_ts_a_id
	)
	select   accCurRiacc.anno_accertamento,
    	     accCurRiacc.numero_accertamento,
        	 accCurRiacc.numero_subaccertamento,
	         accUtilizzabile.importo_utilizzabile,
    	     coalesce(vincolato.totale_vincolato,0) totale_vincolato,
	         accUtilizzabile.importo_utilizzabile -  coalesce(vincolato.totale_vincolato,0) dispVincolabile,
    	     accCurRiacc.movgest_ts_new_id movgest_ts_riacc_id
	from accPrec, accUtilizzabile,
    	 accCurRiacc
	       left join vincolato on (accCurRiacc.movgest_ts_new_id=vincolato.movgest_ts_a_id)
	where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
    and   accUtilizzabile.movgest_ts_id=accCurRiacc.movgest_ts_new_id
	order by  accCurRiacc.anno_accertamento,
	          accCurRiacc.numero_accertamento,
	          accCurRiacc.numero_subaccertamento
	)
	loop
	   --daVincolare:=importoVincoloRiaccertato-(totVincolato);
       raise notice 'daVincolare=%',daVincolare;
	   raise notice 'dispVincolabile=%',movGestRec.dispVincolabile;
	   if daVincolare >= movGestRec.dispVincolabile then
   	        importoVinc:=movGestRec.dispVincolabile;
   	   else importoVinc:=daVincolare;
	   end if;

       raise notice 'importoVinc=%',importoVinc;

	   codResult:=null;
       strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - quota vincolo='||importoVinc::varchar||'.';
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

	   if importoVinc>0 then

        codResult:=null;
        update siac_r_movgest_ts rs
        set    movgest_ts_importo=rs.movgest_ts_importo+importoVinc,
               data_modifica=clock_timestamp()
        where rs.movgest_ts_b_id=movgestTsImpNewId
        and   rs.movgest_ts_a_id=movGestRec.movgest_ts_riacc_id
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null
        returning movgest_ts_r_id into codResult;

        if codResult is null then
          --codResult:=null;
          -- insert into siac_r_movgest_ts
          insert into siac_r_movgest_ts
          (
              movgest_ts_a_id,
              movgest_ts_b_id,
              movgest_ts_importo,
             -- avav_id, 21.02.2018 Sofia
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          values
          (
              movGestRec.movgest_ts_riacc_id,
              movgestTsImpNewId,
              importoVinc,
             -- avavRiaccImpId, 21.02.2018 Sofia
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
          )
          returning movgest_ts_r_id into codResult;
        end if;

        if codResult is null then
        	daCancellare:=true;
        else numeroVinc:=numeroVinc+1;
        end if;
	--   else 	daCancellare:=true;
   	   end if;

       totVincolato:=totVincolato+importoVinc;
  	   daVincolare:=importoVincoloRiaccertato-(totVincolato);
       raise notice 'daVincolare=%',daVincolare;

	   exit when daVincolare<=0 or daCancellare=true;
	end loop;
       raise notice 'daVincolare=%',daVincolare;
       raise notice 'daCancellare=%',daCancellare;

	if daCancellare=false and daVincolare>0 then
    	codResult:=null;
        strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - quota vincolo residuo='||daVincolare::varchar||'.';
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

		-- insert into
        codResult:=null;
        update siac_r_movgest_ts rs
        set    movgest_ts_importo=rs.movgest_ts_importo+daVincolare,
               data_modifica=clock_timestamp()
        where rs.movgest_ts_b_id=movgestTsImpNewId
        and   rs.avav_id=avavRiaccImpId
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null
        returning movgest_ts_r_id into codResult;

        if codResult is null then
          insert into siac_r_movgest_ts
          (
              movgest_ts_b_id,
              avav_id,
              movgest_ts_importo,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          values
          (
              movgestTsImpNewId,
              avavRiaccImpId,
              daVincolare,
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
          )
          returning movgest_ts_r_id into codResult;
        end if;
        raise notice 'codResult=%',codResult;

        if codResult is null then
	       	daCancellare:=true;
        else numeroVinc:=numeroVinc+1;
        end if;

	end if;

    if daCancellare = true then
    	codResult:=null;
        strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - annullamento quote inserite.';
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

    	delete  from siac_r_movgest_ts r
        where r.ente_proprietario_id=enteProprietarioId
        and   r.movgest_ts_b_id=movgestTsImpNewId
        and   r.login_operazione=loginOperazione
        and   r.data_cancellazione is null
        and   r.validita_fine is null;
        numeroVinc:=0;
    end if;

	strMessaggio:=' - Vincoli inseriti num='||numeroVinc::varchar;
	insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
	values
    (faseBilElabId,strMessaggioFinale||strMessaggio||' - FINE .',clock_timestamp(),loginOperazione,enteProprietarioId)
	returning fase_bil_elab_log_id into codResult;

	if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	end if;


    codiceRisultato:=0;
    numeroVincoliCreati:=numeroVinc;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_vincoli(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	dataelaborazione timestamp without time zone,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying)
    RETURNS record
AS $body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    tipoMovGestAccId   integer:=null;

    movGestTsTipoId    integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;

    periodoId         integer:=null;
    periodoPrecId     integer:=null;

    movGestStatoAId   integer:=null;

    movGestRec        record;
    resultRec        record;

    faseBilElabId     integer;
	movGestTsRIdRet   integer;
    numeroVincAgg     integer:=0;


	faseBilElabReimpId integer;
    faseBilElabReAccId integer;

    movgestAccCurRiaccId integer;
    movgesttsAccCurRiaccId  integer;

	bCreaVincolo boolean;
    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';


    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';
    APE_GEST_REIMP_VINC     CONSTANT varchar:='APE_GEST_REIMP_VINC';


    A_MOV_GEST_STATO  CONSTANT varchar:='A';


BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;


	strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP_VINC||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
        strMessaggio :=' Esistenza elaborazione reimputazione vincoli in corso.';
    	raise exception ' Esistenza elaborazione reimputazione vincoli in corso.';
    	return;
    end if;


    strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE VINCOLI IN CORSO.',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, dataElaborazione, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteproprietarioid
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
        strMessaggio  :=' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	raise exception ' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	return;
    end if;

    codResult:=null;
    strMessaggio:='Inserimento LOG.';
    raise notice 'strMesasggio=%',strMessaggio;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' - INIZO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- per I
    strMessaggio:='Lettura id identificativo per tipoMovGest='||IMP_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if tipoMovGestId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

/* -- SIAC-6997 ---------------- INIZIO --------------------
	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioPrecId, periodoPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
    if bilancioPrecId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;
*/ -- SIAC-6997 --------------- FINE ------------------------

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per impegni.';
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

  	codResult:=null;
    select fase.fase_bil_elab_id, fasereimp.bil_id into codResult, bilancioPrecId
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
-- SIAC-6997 --------------- INIZIO ------------------------
--    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
-- SIAC-6997 --------------- FINE ------------------------
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

    if codResult is null then
        strMessaggio :='Elaborazione non effettuabile - Reimputazione impegni non eseguita.';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - ELABORAZIONE REIMPUTAZIONE IMPEGNI NON ESEGUITA.',
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    else faseBilElabReimpId:=codResult;
    end if;


    -- per A
    strMessaggio:='Lettura id identificativo per tipoMovGest='||ACC_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestAccId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
	if tipoMovGestAccId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per accertamenti.';
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

    codResult:=null;
    select fase.fase_bil_elab_id into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestAccId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

	if codResult is not null then
		 faseBilElabReaccId:=codResult;
    end if;



	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
	if bilancioId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

    strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
    select stato.movgest_stato_id into  movGestStatoAId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.movgest_stato_code=A_MOV_GEST_STATO
    and   stato.data_cancellazione is null
    and   stato.validita_fine is null;

	if movGestStatoAId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;


    strMessaggio:='Inizio ciclo per elaborazione.';
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

     for movGestRec in
     (select  mov.movgest_anno::integer anno_impegno,
              mov.movgest_numero::integer numero_impegno,
              (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subimpegno,
              fasevinc.movgest_ts_b_id,
              fasevinc.movgest_ts_a_id,
              fasevinc.movgest_ts_r_id,
              fasevinc.mod_id,
              fasevinc.importo_vincolo,
              fasevinc.avav_id,
              fasevinc.avav_new_id,
              fasevinc.importo_vincolo_new,
              mov.movgest_id,ts.movgest_ts_id,
              fasevinc.reimputazione_vinc_id
	  from siac_t_movgest mov ,
	       siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
	       siac_r_movgest_ts_stato rs,
	       fase_bil_t_reimputazione fase, fase_bil_t_reimputazione_vincoli fasevinc
	  where mov.bil_id=bilancioId
	  and   mov.movgest_tipo_id=tipoMovGestId
	  and   ts.movgest_id=mov.movgest_id
	  and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   rs.movgest_stato_id!=movGestStatoAId
	  and   fase.fasebilelabid=faseBilElabReImpId
	  and   fase.movgestnew_ts_id=ts.movgest_ts_id
	  and   fase.movgest_tipo_id=mov.movgest_tipo_id
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
      and   fasevinc.fasebilelabid=fase.fasebilelabid
      and   fasevinc.reimputazione_id=fase.reimputazione_id
      and   fasevinc.fl_elab is null -- non elaborato e non scartato
      and   fasevinc.mod_tipo_code=fase.mod_tipo_code -- 09.0.2018 Sofia JIRA SIAC-6054
      and   fasevinc.reimputazione_anno=fase.mtdm_reimputazione_anno::integer -- 09.0.2018 Sofia JIRA SIAC-6054
      and   fasevinc.reimputazione_anno=mov.movgest_anno::integer -- 09.0.2018 Sofia JIRA SIAC-6054
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
      order by mov.movgest_anno::integer ,
               mov.movgest_numero::integer,
               (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end),
               fasevinc.movgest_ts_b_id,
               coalesce(fasevinc.movgest_ts_a_id,0)
     )
     loop

        codResult:=null;
	    movgestAccCurRiaccId:=null;
	    movgesttsAccCurRiaccId :=null;
	    movGestTsRIdRet:=null;
		bCreaVincolo:=false;

        strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||coalesce(movGestRec.movgest_ts_r_id,0)||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

        -- caso 1,2
		if movGestRec.movgest_ts_a_id is null then
            bCreaVincolo:=true;
        end if;

        /* caso 3
  		   se il vincolo abbattuto era legato ad un accertamento
		   che non presenta quote riaccertate esso stesso:
		   creare un vincolo nel nuovo bilancio di tipo FPV per la quote di vincolo abbattuta
		   con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno (vedi algoritmo a seguire)
        */
        /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
        if movGestRec.movgest_ts_a_id is not null then
            codResult:=null;
            strMessaggio:=strMessaggio||' - caso con accertamento verifica esistenza quota riacc.';
            raise notice 'strMessaggio=%',strMessaggio;
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

        	with
             accPrec as
             (
        	  select mov.movgest_anno::integer anno_accertamento,
              mov.movgest_numero::integer numero_accertamento,
              (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
              mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioPrecId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_id=movGestRec.movgest_ts_a_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             ),
             accCurRiacc as
             (
              select mov.movgest_anno::integer anno_accertamento,
	                 mov.movgest_numero::integer numero_accertamento,
       			    (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
	                mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   fase.fasebilelabid=faseBilElabReAccId
              and   fase.fl_elab is not null and fase.fl_elab!=''
	    	  and   fase.fl_elab='S'
              and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
              and   mov.movgest_anno::integer<=movGestRec.anno_impegno
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             )
             select  accCurRiacc.movgest_new_id, accCurRiacc.movgest_ts_new_id
                     into movgestAccCurRiaccId, movgesttsAccCurRiaccId
             from accPrec, accCurRiacc
             where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
             limit 1;


			 if movgestAccCurRiaccId is null or movgesttsAccCurRiaccId is null then
             	-- caso 3
                bCreaVincolo:=true;

             else
   	            codResult:=null;
	            strMessaggio:=strMessaggio||' - caso con accertamento e quota riacc.';
                            raise notice 'strMessaggio=%',strMessaggio;

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


                -- caso 4
                -- inserire nuovi vincoli con algoritmo descritto in JIRA per il caso 4
                --- vedere algoritmo
                /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
               select * into resultRec
               from  fnc_fasi_bil_gest_reimputa_vincoli_acc
               (
				  enteProprietarioId,
				  annoBilancio,
				  faseBilElabId,
				  movGestRec.anno_impegno,        -- annoImpegnoRiacc integer,   -- annoImpegno riaccertato
				  movGestRec.movgest_ts_id,       -- movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
				  movGestRec.avav_new_id,         -- avavRiaccImpId   integer,        -- avav_id nuovo
				  movGestRec.importo_vincolo_new, -- importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
				  faseBilElabReAccId,             -- faseId di elaborazione riaccertmaento Acc
				  tipoMovGestAccId,               -- tipoMovGestId Accertamenti
				  movGestRec.movgest_ts_a_id,     -- movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
				  loginOperazione,
				  dataElaborazione
                );
                if resultRec.codiceRisultato=0 then
                	numeroVincAgg:=numeroVincAgg+resultRec.numeroVincoliCreati;

                    strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                	update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='S',
    	                   movgest_ts_b_new_id=movGestRec.movgest_ts_id,
    --    	               movgest_ts_r_new_id=movGestTsRIdRet, non impostato poiche multiplo verso diversi accertamenti pluri
            	       	   bil_new_id=bilancioId
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                else
                	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            		update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='X',
			               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
        	        	   bil_new_id=bilancioId,
	        	           scarto_code='99',
                	       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                end if;
	         end if;

        end if;


	   if bCreaVincolo=true then
            codResult:=null;
            strMessaggio:=strMessaggio||' - inserimento vincolo senza accertamento vincolato.';
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

            movGestTsRIdRet:=null;
            -- 17.06.2020 Sofia SIAC-7593
            update  siac_r_movgest_ts r
            set     movgest_ts_importo=r.movgest_ts_importo+movGestRec.importo_vincolo_new,
                    data_modifica=clock_timestamp()
            where r.movgest_ts_b_id=movGestRec.movgest_ts_id
            and   r.avav_id=movGestRec.avav_new_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            returning r.movgest_ts_r_id into movGestTsRIdRet;


			-- 17.06.2020 Sofia SIAC-7593
            if movGestTsRIdRet is null then

       		-- inserimento siac_t_movgest_ts_r nuovo con i dati presenti in fase_bil_t_reimputazione_vincoli
            -- aggiornamento di fase_bil_t_reimputazione_vincoli
            insert into siac_r_movgest_ts
            (
		        movgest_ts_b_id,
			    movgest_ts_importo,
                avav_id,
                validita_inizio,
                login_operazione,
                ente_proprietario_id
            )
            values
            (
            	movGestRec.movgest_ts_id,
                movGestRec.importo_vincolo_new,
                movGestRec.avav_new_id,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
            )
            returning movgest_ts_r_id into movGestTsRIdRet;
	       end if;


            if movGestTsRIdRet is null then
            	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            	update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='X',
		               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                	   bil_new_id=bilancioId,
	                   scarto_code='99',
                       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;

            else
            	numeroVincAgg:=numeroVincAgg+1;
                strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='S',
                       movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                       movgest_ts_r_new_id=movGestTsRIdRet,
                   	   bil_new_id=bilancioId
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
            end if;
       end if;



       strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||coalesce(movGestRec.movgest_ts_r_id,0)||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

     end loop;

    -- 23.06.2020 Sofia jira SIAC-SIAC-7663 - inizio
    codResult:=null;
    strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';
    strMessaggio:=' Inserimento SIAC_R_MOVGEST_TS_STORICO_IMP_ACC.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    insert into SIAC_R_MOVGEST_TS_STORICO_IMP_ACC
    (
        movgest_ts_id,
        movgest_anno_acc,
        movgest_numero_acc,
        movgest_subnumero_acc,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select query.movgestnew_ts_id,
           query.movgest_anno_acc,
           query.movgest_numero_acc,
           query.movgest_subnumero_acc,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    FROM
    (
    with
    impegni_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           ts.movgest_ts_id movgestnew_ts_id, fase.movgest_ts_id
    from siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         fase_bil_t_reimputazione fase,siac_t_movgest mov
    where fase.fasebilelabid=faseBilElabReimpId
    and   fase.movgestnew_ts_id is not null
    and   fase.fl_elab='S'
    and   ts.movgest_ts_id=fase.movgestnew_ts_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   mov.movgest_id=ts.movgest_id
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    ),
    impegni_prec as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov_a.movgest_anno::integer movgest_anno_acc, mov_a.movgest_numero::integer movgest_numero_acc,
           ( case when tipots_a.movgest_ts_tipo_code='T' then 0 else ts_a.movgest_ts_code::integer end ) movgest_subnumero_acc,
           ts.movgest_ts_id movgest_ts_b_id,
           ts_a.movgest_ts_id movgest_ts_a_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r,
         siac_t_movgest mov_a,siac_d_movgest_tipo tipo_a,siac_t_movgest_Ts ts_a,siac_d_movgest_ts_tipo tipots_a,
         siac_r_movgest_ts_stato rs_a,siac_d_movgest_stato stato_a,
         fase_bil_t_reimputazione fase
    where fase.fasebilelabid=faseBilElabReimpId
    and   fase.movgestnew_ts_id is not null
    and   fase.fl_elab='S'
    and   ts.movgest_ts_id=fase.movgest_ts_id
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='I'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_b_id=ts.movgest_ts_id
    and   ts_a.movgest_ts_id=r.movgest_ts_a_id
    and   mov_a.movgest_id=ts_a.movgest_id
    and   tipots_a.movgest_ts_tipo_id=ts_a.movgest_ts_tipo_id
    and   tipo_a.movgest_tipo_id=mov_a.movgest_tipo_id
    and   tipo_a.movgest_tipo_code='A'
    and   mov_a.bil_id=bilancioPrecId
    and   rs_a.movgest_ts_id=ts_a.movgest_ts_id
    and   stato_a.movgest_stato_id=rs_a.movgest_stato_id
    and   stato_a.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   rs_a.data_cancellazione is null
    and   rs_a.validita_fine is null
    and   mov_a.data_cancellazione is null
    and   mov_a.validita_fine is null
    and   ts_a.data_cancellazione is null
    and   ts_a.validita_fine is null
    ),
    acc_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           r.movgest_ts_a_id,
           r.movgest_ts_b_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_a_id=ts.movgest_ts_id
    and   r.movgest_ts_b_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    )
    select distinct
           impegni_cur.movgestnew_ts_id,
           impegni_prec.movgest_anno_acc,
           impegni_prec.movgest_numero_acc,
           impegni_prec.movgest_subnumero_acc
    from impegni_cur, impegni_prec
    where impegni_cur.movgest_ts_id=impegni_prec.movgest_ts_b_id
    and   not exists
    (select 1
     from acc_cur
     where acc_cur.movgest_ts_b_id=impegni_cur.movgestnew_ts_id
     and   acc_cur.movgest_anno=impegni_prec.movgest_anno_acc
     and   acc_cur.movgest_numero=impegni_prec.movgest_numero_acc
     and   acc_cur.movgest_subnumero=impegni_prec.movgest_subnumero_acc )
     ) query
     where
     not exists
     (select 1
      from SIAC_R_MOVGEST_TS_STORICO_IMP_ACC rStorico
      where rStorico.ente_proprietario_id=enteProprietarioId
      and   rStorico.movgest_ts_id=query.movgestnew_ts_id
      and   rStorico.movgest_anno_acc=query.movgest_anno_acc
      and   rStorico.movgest_numero_acc=query.movgest_numero_acc
      and   rStorico.movgest_subnumero_acc=query.movgest_subnumero_acc
      and   rStorico.data_cancellazione is null
      and   rStorico.validita_fine is null);
    codResult:=null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% codResult=%',strMessaggio, codResult;
    -- 23.06.2020 Sofia jira SIAC-SIAC-7663 - fine

-- SIAC-6997 ---------------- INIZIO --------------------

    strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' - FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

-- SIAC-6997 ---------------- FINE --------------------

     strMessaggio:='Aggiornamento stato fase bilancio OK.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='OK',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_REIMP_VINC||
                                 ' OK. INSERITI NUOVI VINCOLI NUM='||
                                 coalesce(numeroVincAgg,0)||'.'
     where fase_bil_elab_id=faseBilElabId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. impegni.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReimpId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. accertamenti.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReAccId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_popola(
	p_fasebilelabid integer,
	p_enteproprietarioid integer,
	p_annobilancio integer,
	p_loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
    componenteFittiziaId integer,
    componenteFrescoId integer,
    componenteFPVId integer,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying)
RETURNS record
AS $body$

DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    v_faseBilElabId    integer;
    v_bil_attr_id      integer;
    v_attr_code        varchar;
-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio     integer;
-- SIAC-6997 ---------------- FINE --------------------
    MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';
    CAP_UG_TIPO        CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO        CONSTANT varchar:='CAP-EG';
    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';

    MOVGEST_IMP_TIPO    CONSTANT  varchar:='I';
    MACROAGGREGATO_TIPO CONSTANT varchar:='MACROAGGREGATO';
    TITOLO_SPESA_TIPO   CONSTANT varchar:='TITOLO_SPESA';

    faseRec record;
    faseElabRec record;
    recmovgest  record;

    attoAmmId integer:=null;

    -- 05.06.2020 Sofia Jira SIAC-7593
    totModCollegAcc numeric:=null;
    codEsito       varchar(10):=null;
    mod_rec        record;
    faseReimpFrescoId integer:=null;
    faseReimpFpvId integer:=null;


    motivoREIMP   CONSTANT varchar:='REIMP';
    motivoREANNO  CONSTANT varchar:='REANNO';
BEGIN

    codiceRisultato:=null;
    messaggioRisultato:=null;
    strMessaggioFinale:='Inizio.';

    strMessaggio := 'prima del loop';

-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio := p_annoBilancio;
    if motivo = motivoREIMP then
       v_annobilancio := p_annoBilancio - 1;
    end if;
-- SIAC-6997 ----------------  FINE --------------------

    for recmovgest in (select
					   --siac_t_bil_elem
					   bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code tipo
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo impoInizImpegno
					  ,detts.movgest_ts_det_importo     impoAttImpegno
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
					  ,sum(dettsmod.movgest_ts_det_importo)  importoModifica
				from siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato -- 07.02.2018 Sofia siac-5368
				where bil.ente_proprietario_id=p_enteProprietarioId
				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--				and   per.anno::integer=p_annoBilancio-1
                and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id = modificaTipo.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
                and   modifica.elab_ror_reanno = FALSE
                and   modificaTipo.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code=p_movgest_tipo_code--'I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code=p_movgest_tipo_code--'I' -- 'A'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
               	group by

				       bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo
					  ,detts.movgest_ts_det_importo
					  --,dettsmod.movgest_ts_det_importo  importoModifica
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
				order by
				 		 dettsmod.mtdm_reimputazione_anno::integer
				 		,modificaTipo.mod_tipo_code
				 		--,tsmov.movgest_ts_code::integer    ?? serve????
						,movgest.movgest_anno::integer
                        ,movgest.movgest_numero::integer
                        ,tipo desc --tipots.movgest_ts_tipo_code desc,



    --Raggruppate per anno reimputazione, motivo anno/numero impegno/sub,


    ) loop

		-- 07.02.2018 Sofia siac-5368
       	strMessaggio := 'Lettura attoamm_id prima di inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
        		raise notice 'strMessaggio=%',strMessaggio;

        attoAmmId:=null;
        select r.attoamm_id into attoAmmId
        from siac_r_movgest_ts_atto_amm r
        where r.movgest_ts_id=recmovgest.movgest_ts_id
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        -- 05.06.2020 Sofia SIAC-7593
		-- calcolo della quota di reimp che deve rimanere su componente Fresco
        -- modifica di impegno collegata a modifiche di accertamento con Vincolo verso acc.
        -- se esiste collegamento ma non il vincolo verso accertamento deve andare su
        -- componente FPV
        -- 23.07.2020 Sofia vedi commento successivo su componente Fresco anche in assenza di vincolo
        -- basta la presenza di colleg. spesa-entrata
        if p_movgest_tipo_code=MOVGEST_IMP_TIPO then
          strMessaggio := 'Calcolo totale entrate collegate a impegno per calcolo Fresco '
                        ||' prima di inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='
                        ||recmovgest.movgest_ts_id::varchar
                        ||' Componente '
                        ||(case when componenteFittiziaId is not null then 'Fittizia' else 'Fresca'  end )
                        ||' ID= '
                        ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFrescoId::varchar  end )
                        ||'.';
          raise notice 'strMessaggio=%',strMessaggio;
          totModCollegAcc:=0;
          /*select coalesce(sum(rmod.movgest_ts_det_mod_importo),0) into totModCollegAcc
          from siac_t_bil bil ,
               siac_t_periodo per,
               siac_t_movgest mov,siac_d_movgest_tipo tipo,
               siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
               siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
               siac_t_movgest_ts_det_mod  dettsmod,
               siac_t_modifica mod,siac_d_modifica_tipo tipomod,
               siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
               siac_r_movgest_ts_det_mod rmod,
               siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
               siac_t_modifica modAcc,
               siac_r_movgest_Ts rvincAcc
          where bil.ente_proprietario_id=p_enteProprietarioId  -- ente_proprietario
          and   per.periodo_id=bil.periodo_id
          and   per.anno::integer=v_annoBilancio              -- anno_bilancio
          and   tipo.ente_proprietario_id=bil.ente_proprietario_id
          and   tipo.movgest_tipo_code=p_movgest_tipo_code     -- tipo_impegno
          and   mov.movgest_tipo_id=tipo.movgest_tipo_id
          and   mov.bil_id=bil.bil_id
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- impegno
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   detts.movgest_ts_id=ts.movgest_ts_id
          and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
          and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
          and   dettsmod.movgest_ts_det_importo<0
          and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
          and   modstato.mod_stato_id=rmodstato.mod_stato_id
          and   modstato.mod_stato_code='V'
          and   mod.mod_id=rmodstato.mod_id
          and   tipomod.mod_tipo_id =  mod.mod_tipo_id
          and   mod.elab_ror_reanno = FALSE
          and   tipomod.mod_tipo_code = motivo  -- motivo
          and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code -- mod_tipo_code
          and   dettsmod.mtdm_reimputazione_anno is not null
          and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   dettsmod.mtdm_reimputazione_flag is true -- ROR
          and   rmod.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id   -- spesa_id collegata a entrata_id
          and   detmodAcc.movgest_ts_det_mod_id=rmod.movgest_ts_det_mod_entrata_id
          and   rsModAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
          and   rsmodAcc.mod_stato_id=modstato.mod_stato_id -- V
          and   modAcc.mod_id=rsModAcc.mod_id
          and   modAcc.mod_tipo_id=tipomod.mod_tipo_id -- motivo entrata uguale spesa
          and   modAcc.elab_ror_reanno = FALSE
          and   detmodAcc.mtdm_reimputazione_anno is not null
          and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   detmodAcc.mtdm_reimputazione_flag is true -- ROR
          and   rvincAcc.movgest_Ts_b_Id=recmovgest.movgest_ts_id
          and   rvincacc.movgest_ts_a_id=detmodAcc.movgest_ts_id
          and   rmodstato.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   detts.data_cancellazione is null
          and   detts.validita_fine is null
          and   dettsmod.data_cancellazione is null
          and   dettsmod.validita_fine is null
          and   rmodstato.data_cancellazione is null
          and   rmodstato.validita_fine is null
          and   mod.data_cancellazione is null
          and   mod.validita_fine is null
          and   rmod.data_cancellazione is null
          and   rmod.validita_fine is null
          and   detmodAcc.data_cancellazione is null
          and   detmodAcc.validita_fine is null
          and   rsModAcc.data_cancellazione is null
          and   rsModAcc.validita_fine is null
          and   modacc.data_cancellazione is null
          and   modAcc.validita_fine is null
          and   rvincacc.data_cancellazione is null
          and   rvincacc.validita_fine is null;*/

          -- 23.07.2020 Sofia SIAC-7593 in seguito a scambio mail con Gambino e test in collaudo
          -- emerge che il fresco si calcola sul collegamento tra modifiche spesa-entrata
          -- anche in assenza di vincoli
          select coalesce(sum(rmod.movgest_ts_det_mod_importo),0) into totModCollegAcc
          from siac_t_bil bil ,
               siac_t_periodo per,
               siac_t_movgest mov,siac_d_movgest_tipo tipo,
               siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
               siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
               siac_t_movgest_ts_det_mod  dettsmod,
               siac_t_modifica mod,siac_d_modifica_tipo tipomod,
               siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
               siac_r_movgest_ts_det_mod rmod,
               siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
               siac_t_modifica modAcc--,
               --siac_r_movgest_Ts rvincAcc
          where bil.ente_proprietario_id=p_enteProprietarioId  -- ente_proprietario
          and   per.periodo_id=bil.periodo_id
          and   per.anno::integer=v_annoBilancio              -- anno_bilancio
          and   tipo.ente_proprietario_id=bil.ente_proprietario_id
          and   tipo.movgest_tipo_code=p_movgest_tipo_code     -- tipo_impegno
          and   mov.movgest_tipo_id=tipo.movgest_tipo_id
          and   mov.bil_id=bil.bil_id
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- impegno
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   detts.movgest_ts_id=ts.movgest_ts_id
          and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
          and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
          and   dettsmod.movgest_ts_det_importo<0
          and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
          and   modstato.mod_stato_id=rmodstato.mod_stato_id
          and   modstato.mod_stato_code='V'
          and   mod.mod_id=rmodstato.mod_id
          and   tipomod.mod_tipo_id =  mod.mod_tipo_id
          and   mod.elab_ror_reanno = FALSE
          and   tipomod.mod_tipo_code = motivo  -- motivo
          and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code -- mod_tipo_code
          and   dettsmod.mtdm_reimputazione_anno is not null
          and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   dettsmod.mtdm_reimputazione_flag is true -- ROR
          and   rmod.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id   -- spesa_id collegata a entrata_id
          and   detmodAcc.movgest_ts_det_mod_id=rmod.movgest_ts_det_mod_entrata_id
          and   rsModAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
          and   rsmodAcc.mod_stato_id=modstato.mod_stato_id -- V
          and   modAcc.mod_id=rsModAcc.mod_id
          and   modAcc.mod_tipo_id=tipomod.mod_tipo_id -- motivo entrata uguale spesa
          and   modAcc.elab_ror_reanno = FALSE
          and   detmodAcc.mtdm_reimputazione_anno is not null
          and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   detmodAcc.mtdm_reimputazione_flag is true -- ROR
          --and   rvincAcc.movgest_Ts_b_Id=recmovgest.movgest_ts_id
          --and   rvincacc.movgest_ts_a_id=detmodAcc.movgest_ts_id
          and   rmodstato.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   detts.data_cancellazione is null
          and   detts.validita_fine is null
          and   dettsmod.data_cancellazione is null
          and   dettsmod.validita_fine is null
          and   rmodstato.data_cancellazione is null
          and   rmodstato.validita_fine is null
          and   mod.data_cancellazione is null
          and   mod.validita_fine is null
          and   rmod.data_cancellazione is null
          and   rmod.validita_fine is null
          and   detmodAcc.data_cancellazione is null
          and   detmodAcc.validita_fine is null
          and   rsModAcc.data_cancellazione is null
          and   rsModAcc.validita_fine is null
          and   modacc.data_cancellazione is null
          and   modAcc.validita_fine is null;
          --and   rvincacc.data_cancellazione is null
          --and   rvincacc.validita_fine is null;

        end if;

        raise notice 'totModCollegAcc per componente fresc=%',totModCollegAcc;
		-- COMPONENTE FRESCA
        -- se il totale collegato a modifiche accertamenti !=0
        -- si passa come importo reimputazione totModCollegAcc
        -- se passata la componente Fittizia si passa Fittizia
        -- diversamente si passa Fresco

        if totModCollegAcc is not null and totModCollegAcc!=0 then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='
                        ||recmovgest.movgest_ts_id::varchar
                        ||' Componente '
                        ||(case when componenteFittiziaId is not null then 'Fittizia' else 'Fresca'  end )
                        ||' ID= '
                        ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFrescoId::varchar  end )
                        ||'.';
          raise notice 'strMessaggio=%',strMessaggio;
          --codResult:=null;
          faseReimpFrescoId:=null;
          insert into  fase_bil_t_reimputazione (
           --siac_t_bil_elem
           faseBilElabId
          ,bil_id
          ,elemId_old
          ,elem_code
          ,elem_code2
          ,elem_code3
          ,elem_tipo_code
          -- siac_t_movgest
          ,movgest_id
          ,movgest_anno
          ,movgest_numero
          ,movgest_desc
          ,movgest_tipo_id
          ,parere_finanziario
          ,parere_finanziario_data_modifica
          ,parere_finanziario_login_operazione
          -- siac_t_movgest_ts
          ,movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,movgest_ts_desc
          ,movgest_ts_tipo_id
          ,movgest_ts_id_padre
          ,ordine
          ,livello
          ,movgest_ts_scadenza_data
          ,siope_tipo_debito_id
          ,siope_assenza_motivazione_id
          --siac_t_movgest_ts_dett
          ,tipo
          ,movgest_ts_det_tipo_code
          ,mod_tipo_code
          ,movgest_ts_det_tipo_id
          ,impoInizImpegno
          ,impoAttImpegno
          ,importoModifica
          ,mtdm_reimputazione_anno
          ,mtdm_reimputazione_flag
          , attoamm_id        -- 07.02.2018 Sofia siac-5368
          , movgest_stato_id  -- 07.02.2018 Sofia siac-5368
          , importo_reimputato -- 05.06.2020 Sofia siac-7593
          , importo_modifica_entrata -- 05.06.2020 Sofia siac-7593
          , coll_mod_entrata      -- 05.06.2020 Sofia siac-7593
          , coll_det_mod_entrata    -- 08.06.2020 Sofia siac-7593
          ,elem_det_comp_tipo_id    -- 05.06.2020 Sofia siac-7593
          ,login_operazione
          ,ente_proprietario_id
          ,data_creazione
          ,fl_elab
          ,scarto_code
          ,scarto_desc
          ) values (
          --siac_t_bil_elem
          --siac_t_bil_elem
           p_faseBilElabId
          ,recmovgest.bil_id
          ,recmovgest.elem_id
          ,recmovgest.elem_code
          ,recmovgest.elem_code2
          ,recmovgest.elem_code3
          ,recmovgest.elem_tipo_code
          -- siac_t_movgest
          ,recmovgest.movgest_id
          ,recmovgest.movgest_anno
          ,recmovgest.movgest_numero
          ,recmovgest.movgest_desc
          ,recmovgest.movgest_tipo_id
          ,recmovgest.parere_finanziario
          ,recmovgest.parere_finanziario_data_modifica
          ,recmovgest.parere_finanziario_login_operazione
          -- siac_t_movgest_ts
          ,recmovgest.movgest_ts_id
          ,recmovgest.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,recmovgest.movgest_ts_desc
          ,recmovgest.movgest_ts_tipo_id
          ,recmovgest.movgest_ts_id_padre
          ,recmovgest.ordine
          ,recmovgest.livello
          ,recmovgest.movgest_ts_scadenza_data
          ,recmovgest.siope_tipo_debito_id
          ,recmovgest.siope_assenza_motivazione_id
          --siac_t_movgest_ts_dett
          ,recmovgest.tipo
          ,recmovgest.movgest_ts_det_tipo_code
          ,recmovgest.mod_tipo_code
          ,recmovgest.movgest_ts_det_tipo_id
          ,recmovgest.impoInizImpegno
          ,recmovgest.impoAttImpegno
          ,recmovgest.importoModifica
          ,recmovgest.mtdm_reimputazione_anno
          ,recmovgest.mtdm_reimputazione_flag
          , attoAmmId                    -- 07.02.2018 Sofia siac-5368
          , recmovgest.movgest_stato_id  -- 07.02.2018 Sofia siac-5368
          , totModCollegAcc -- 05.06.2020 Sofia siac-7593 importo_reimputato
          , totModCollegAcc -- 05.06.2020 Sofia siac-7593 importo_modifica_entrata
          , true            -- 05.06.2020 Sofia siac-7593 colleg_mod_entrata
          , true            -- 05.06.2020 Sofia siac-7593 colleg_det_mod_entrata
          , (case when componenteFittiziaId is not null then componenteFittiziaId else componenteFrescoId  end ) -- 05.06.2020 Sofia siac-7593
          ,p_loginoperazione
          ,p_enteProprietarioId
          ,p_dataElaborazione
          ,'N'
          ,null
          ,null
          )
          -- 09.06.2020 Sofia Jira SIAC-7593
          --returning reimputazione_id into codResult;
          --raise notice 'dopo inserimento codResult=%',codResult;
		  returning reimputazione_id into faseReimpFrescoId;
          raise notice 'dopo inserimento faseReimpFrescoId=%',faseReimpFrescoId;
        end if;

		-- 05.06.2020 Sofia SIAC-7593
        -- COMPONENTE FPV
        -- si passa come importo di reimputazione
        -- l'importo di modifica - il totale collegato a modifiche accertamenti
        -- se totModCollegAcc=0 o nullo e non ci sono collegamenti
        -- l' importo di reimputazione resta importo di modifica
        -- se passata la componente Fittizia si passa Fittizia
        -- diversamente si passa FPV
        -- 08.06.2020 Sofia siac-7593
        -- se (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))!=0 si procede con inserimento

        if (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))!=0 then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFPVId::varchar  end )
                          ||'.';
          raise notice 'strMessaggio=%',strMessaggio;
          --codResult:=null; -- 31.01.2018 Sofia siac-5368
          faseReimpFpvId:=null; -- 09.06.2020 Sofia SIAC-7593
          insert into  fase_bil_t_reimputazione
          (
             --siac_t_bil_elem
             faseBilElabId
            ,bil_id
            ,elemId_old
            ,elem_code
            ,elem_code2
            ,elem_code3
            ,elem_tipo_code
            -- siac_t_movgest
            ,movgest_id
            ,movgest_anno
            ,movgest_numero
            ,movgest_desc
            ,movgest_tipo_id
            ,parere_finanziario
            ,parere_finanziario_data_modifica
            ,parere_finanziario_login_operazione
            -- siac_t_movgest_ts
            ,movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
            ,movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
            ,movgest_ts_desc
            ,movgest_ts_tipo_id
            ,movgest_ts_id_padre
            ,ordine
            ,livello
            ,movgest_ts_scadenza_data
            ,siope_tipo_debito_id
            ,siope_assenza_motivazione_id
            --siac_t_movgest_ts_dett
            ,tipo
            ,movgest_ts_det_tipo_code
            ,mod_tipo_code
            ,movgest_ts_det_tipo_id
            ,impoInizImpegno
            ,impoAttImpegno
            ,importoModifica
            ,mtdm_reimputazione_anno
            ,mtdm_reimputazione_flag
            , attoamm_id        -- 07.02.2018 Sofia siac-5368
            , movgest_stato_id  -- 07.02.2018 Sofia siac-5368
            , importo_reimputato -- 05.06.2020 Sofia siac-7593
            , importo_modifica_entrata -- 05.06.2020 Sofia siac-7593
            , coll_mod_entrata      -- 05.06.2020 Sofia siac-7593
            , coll_det_mod_entrata    -- 08.06.2020 Sofia siac-7593
            , elem_det_comp_tipo_id    -- 05.06.2020 Sofia siac-7593
            ,login_operazione
            ,ente_proprietario_id
            ,data_creazione
            ,fl_elab
            ,scarto_code
            ,scarto_desc
        ) values (
        --siac_t_bil_elem
            --siac_t_bil_elem
             p_faseBilElabId
            ,recmovgest.bil_id
            ,recmovgest.elem_id
            ,recmovgest.elem_code
            ,recmovgest.elem_code2
            ,recmovgest.elem_code3
            ,recmovgest.elem_tipo_code
            -- siac_t_movgest
            ,recmovgest.movgest_id
            ,recmovgest.movgest_anno
            ,recmovgest.movgest_numero
            ,recmovgest.movgest_desc
            ,recmovgest.movgest_tipo_id
            ,recmovgest.parere_finanziario
            ,recmovgest.parere_finanziario_data_modifica
            ,recmovgest.parere_finanziario_login_operazione
            -- siac_t_movgest_ts
            ,recmovgest.movgest_ts_id
            ,recmovgest.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
            ,recmovgest.movgest_ts_desc
            ,recmovgest.movgest_ts_tipo_id
            ,recmovgest.movgest_ts_id_padre
            ,recmovgest.ordine
            ,recmovgest.livello
            ,recmovgest.movgest_ts_scadenza_data
            ,recmovgest.siope_tipo_debito_id
            ,recmovgest.siope_assenza_motivazione_id
            --siac_t_movgest_ts_dett
            ,recmovgest.tipo
            ,recmovgest.movgest_ts_det_tipo_code
            ,recmovgest.mod_tipo_code
            ,recmovgest.movgest_ts_det_tipo_id
            ,recmovgest.impoInizImpegno
            ,recmovgest.impoAttImpegno
            ,recmovgest.importoModifica
            ,recmovgest.mtdm_reimputazione_anno
            ,recmovgest.mtdm_reimputazione_flag
            , attoAmmId                    -- 07.02.2018 Sofia siac-5368
            , recmovgest.movgest_stato_id  -- 07.02.2018 Sofia siac-5368
            , (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))     -- 05.06.2020 Sofia siac-7593 importo_reimputato
            , totModCollegAcc     -- 05.06.2020 Sofia siac-7593 importo_modifica_entrata
            , (case when coalesce(totModCollegAcc,0)!=0 then true else false  end) -- 05.06.2020 Sofia siac-7593 colleg_mod_entrata
            , false               -- 08.06.2020 Sofia siac-7593 colleg_det_mod_entrata
            , (case when componenteFittiziaId is not null then componenteFittiziaId else componenteFPVId  end ) -- 05.06.2020 Sofia siac-7593
            ,p_loginoperazione
            ,p_enteProprietarioId
            ,p_dataElaborazione
            ,'N'
            ,null
            ,null
      )
      -- 09.06.2020 Sofia SIAC-7593
      --returning reimputazione_id into codResult; -- 31.01.2018 Sofia siac-5788
      --raise notice 'dopo inserimento codResult=%',codResult;
      returning reimputazione_id into faseReimpFpvId;
      raise notice 'dopo inserimento faseReimpFpvId=%',faseReimpFpvId;
    end if;


    -- 08.06.2020 Sofia Jira siac-7593 - inizio - aggiornamento vincoli non aggiornati da Contabilia
    if p_movgest_tipo_code=MOVGEST_IMP_TIPO then
      strMessaggio := 'Aggiornamento vincoli non aggiornati da contabilia - esec fnc_siac_riaccertamento_reimp - inizio.';
      raise notice 'strMessaggio=%',strMessaggio;
      for mod_rec in
      (
       select mod.mod_id
       from  siac_t_bil bil ,
             siac_t_periodo per,
             siac_t_movgest mov,siac_d_movgest_tipo tipo,
             siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
             siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
             siac_t_movgest_ts_det_mod  dettsmod,
             siac_t_modifica mod,siac_d_modifica_tipo tipomod,
             siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato
        where bil.ente_proprietario_id=p_enteProprietarioId  -- ente_proprietario
        and   per.periodo_id=bil.periodo_id
        and   per.anno::integer=v_annoBilancio              -- anno_bilancio
        and   tipo.ente_proprietario_id=bil.ente_proprietario_id
        and   tipo.movgest_tipo_code=p_movgest_tipo_code     -- tipo_impegno
        and   mov.movgest_tipo_id=tipo.movgest_tipo_id
        and   mov.bil_id=bil.bil_id
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- impegno
        and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
        and   detts.movgest_ts_id=ts.movgest_ts_id
        and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
        and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
        and   dettsmod.movgest_ts_det_importo<0
        and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
        and   modstato.mod_stato_id=rmodstato.mod_stato_id
        and   modstato.mod_stato_code='V'
        and   mod.mod_id=rmodstato.mod_id
        and   tipomod.mod_tipo_id =  mod.mod_tipo_id
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo  -- motivo
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code -- mod_tipo_code
        and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
        and   dettsmod.mtdm_reimputazione_flag is true -- ROR
        and   rmodstato.validita_fine is null
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   ts.data_cancellazione is null
        and   ts.validita_fine is null
        and   detts.data_cancellazione is null
        and   detts.validita_fine is null
        and   dettsmod.data_cancellazione is null
        and   dettsmod.validita_fine is null
        and   rmodstato.data_cancellazione is null
        and   rmodstato.validita_fine is null
        and   mod.data_cancellazione is null
        and   mod.validita_fine is null
        order by 1
      )
      loop
         codEsito:=null;
         strMessaggio := 'Aggiornamento vincoli non aggiornati da contabilia - esec fnc_siac_riaccertamento_reimp mod_id='
         ||mod_rec.mod_id::varchar||'.';
         raise notice 'strMessaggio=%',strMessaggio;
         select
         fnc_siac_riaccertamento_reimp -- da implementare
         (
          mod_rec.mod_id,
          p_loginoperazione||'-'||motivo,
          'INSERIMENTO'
         ) into codEsito;
         strMessaggio:=strMessaggio||'Esito='||codEsito||'.';
         raise notice 'strMessaggio=%',strMessaggio;
         --codEsito:='ko';
         if codEsito='ko' then
         	raise exception '%',strMessaggio;
         end if;
     end loop;
     strMessaggio := 'Aggiornamento vincoli non aggiornati da contabilia - esec fnc_siac_riaccertamento_reimp - fine.';
     raise notice 'strMessaggio=%',strMessaggio;
     end if;
    -- 08.06.2020 Sofia Jira siac-7593 - fine


    -- 08.06.2020 Sofia Jira siac-7593 - inizio
    -- mod spesa collegata a mod entrata con quadratura ( importo_mod_spesa=tot.coll. importo_mod_entrata)
    --- A
    if ( faseReimpFrescoId is not null or faseReimpFpvId is not null ) and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then
        -- A.1
        -- con o senza vincolo verso accertamento : si creano impegni reimputati su componente fresco,
        -- con vincolo verso l'accertamento collegato tramite modifica
        -- dall'acc collegato in partenza
        -- impostare il caso di accertamento (come adesso ) per farlo andare al nuovo accertamento o FPV come adesso
        -- caso A.2 non esiste 23.07.2020 Sofia
        -- A.2
        -- senza vincolo verso accertamento : si creano impegni reimputati su componente FPV
        -- A.2.1 se ROR vincolo verso FPV ( anche se in partenza non esiste )
        -- A.2.2 se REANNO vincolo verso accertamento reimputato da accertamento collegato
        -- tramite modifica di importo
        -- se AAM potrebbe andare a FPV ma al momento non gestire in quanto potrebbe non verificarsi mai
        -- A.3 - annegato negli altri
        -- senza vincolo si crea nuovo vincolo a FPV
        -- gestito con A.2

        if faseReimpFrescoId is not null then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'Fresca'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFrescoId::varchar  end )
                          ||'. Caso A.1 modfica spesa-modifica entra e vincolo entrata.';
          raise notice 'A.1 strMessaggio=%',strMessaggio;
          codResult:=null;
          -- A.1 faseReimpFrescoId
          insert into   fase_bil_t_reimputazione_vincoli
          (
            reimputazione_id,
            fasebilelabid,
            bil_id,
            mod_id,
            mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
            reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
            movgest_ts_r_id,
            movgest_ts_b_id,
            movgest_ts_a_id,
            importo_vincolo,
            avav_new_id,
            importo_vincolo_new,
            data_creazione,
            login_operazione,
            ente_proprietario_id
          )
          (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 --rts.movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
                 detmodAcc.movgest_ts_id movgest_ts_a_id,    -- movgest_ts_a_id
                 --rts.movgest_ts_a_id,            -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 --coalesce(rts.movgest_ts_importo,0) importo_vincolo,
                 -- abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
                 rmodAcc.movgest_ts_det_mod_importo  importo_vincolo_new -- 23.07.2020 Sofia
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                    -- siac_r_movgest_ts rts,
                     siac_r_movgest_ts_det_mod rmodAcc,
                     siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                     siac_t_modifica modAcc--,
                     --siac_r_modifica_vincolo rvinc -- inserito da mod.entrata
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
  			    and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   detmodAcc.movgest_ts_det_mod_id=rmodAcc.movgest_ts_det_mod_entrata_id
                and   detmodAcc.mtdm_reimputazione_anno is not null
                and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   detmodAcc.mtdm_reimputazione_flag is true
                and   rsmodAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
                and   rsmodAcc.mod_stato_id=modstato.mod_stato_id
                and   modAcc.mod_id=rsmodAcc.mod_id
                and   modAcc.mod_tipo_id=mod.mod_tipo_id
                and   modAcc.elab_ror_reanno = FALSE
               -- and   rts.movgest_ts_a_id=detmodAcc.movgest_ts_id
               -- and   rts.movgest_ts_b_id=ts.movgest_ts_id
               -- and   rvinc.movgest_ts_r_id=rts.movgest_ts_r_id
               -- and   rvinc.mod_Id=modAcc.mod_id
               -- and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                --and   rvinc.data_cancellazione is null
                --and   rvinc.validita_fine is null
               -- and   rts.data_cancellazione is null
               -- and   rts.validita_fine is null
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                and   rsmodAcc.data_cancellazione is null
                and   rsmodAcc.validita_fine is null
                and   detmodAcc.data_cancellazione is null
                and   detmodAcc.validita_fine is null
                and   modAcc.data_cancellazione is null
                and   modAcc.validita_fine is null
            )
            select faseReimpFrescoId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo A.1=%',codResult;
       end if;

       /* 23.07.2020 Sofia vedasi confronto con Gambino per cui
          se esiste collegamento tra modifica di spesa-entrata
          sempre Fresco e vincolo verso accertamento
          anche se non esiste vincolo in partenza
       if faseReimpFpvId is not null then
         -- A.2 faseReimpFpvId
         -- senza vincolo verso accertamento : si creano impegni reimputati su componente FPV
         -- A.2.1 se ROR vincolo verso FPV ( anche se in partenza non esiste )
         if motivo=motivoREIMP then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso A.2.1 modfica spesa-modifica entra senza vincolo entrata '||motivoREIMP||'.';
          raise notice 'A.2.1 strMessaggio=%',strMessaggio;
          codResult:=null;
          insert into   fase_bil_t_reimputazione_vincoli
          (
            reimputazione_id,
            fasebilelabid,
            bil_id,
            mod_id,
            mod_tipo_code,
            reimputazione_anno,
            movgest_ts_r_id,
            movgest_ts_b_id,
            movgest_ts_a_id,
            importo_vincolo,
            avav_new_id,
            importo_vincolo_new,
            data_creazione,
            login_operazione,
            ente_proprietario_id
          )
          (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 NULL::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,  -- movgest_ts_b_id
                 NULL::integer movgest_ts_a_id,              -- movgest_ts_a_id
                 NULL::numeric importo_vincolo,
                 sum(rmodAcc.movgest_ts_det_mod_importo)  importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_r_movgest_ts_det_mod rmodAcc,
                     siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                     siac_t_modifica modAcc
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   detmodAcc.movgest_ts_det_mod_id=rmodAcc.movgest_ts_det_mod_entrata_id
                and   rsmodAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
                and   rsmodAcc.mod_stato_id=modstato.mod_stato_id
                and   modAcc.mod_id=rsmodAcc.mod_id
                and   modAcc.mod_tipo_id=mod.mod_tipo_id
				and   modAcc.elab_ror_reanno = FALSE
                and   detmodAcc.mtdm_reimputazione_anno is not null
                and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   detmodAcc.mtdm_reimputazione_flag is true
                and   not exists
                (
                select 1
                from siac_r_movgest_ts rts
                where rts.movgest_ts_b_id=ts.movgest_ts_id
                and   rts.movgest_ts_a_id=detmodAcc.movgest_ts_id
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                and   rsmodAcc.data_cancellazione is null
                and   rsmodAcc.validita_fine is null
                and   detmodAcc.data_cancellazione is null
                and   detmodAcc.validita_fine is null
                and   modAcc.data_cancellazione is null
                and   modAcc.validita_fine is null
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new::numeric,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo A.2.1=%',codResult;
        end if; -- motivo=motivoREIMP


        -- A.2 faseReimpFpvId
        -- senza vincolo verso accertamento : si creano impegni reimputati su componente FPV
        -- A.2.2 se REANNO vincolo verso accertamento reimputato da accertamento collegato
        if motivo=motivoREANNO then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso A.2.2 modfica spesa-modifica entra senza vincolo entrata '||motivoREANNO||'.';
          raise notice 'A.2.2 strMessaggio=%',strMessaggio;
		  codResult:=null;
          insert into   fase_bil_t_reimputazione_vincoli
          (
            reimputazione_id,
            fasebilelabid,
            bil_id,
            mod_id,
            mod_tipo_code,
            reimputazione_anno,
            movgest_ts_r_id,
            movgest_ts_b_id,
            movgest_ts_a_id,
            importo_vincolo,
            avav_new_id,
            importo_vincolo_new,
            data_creazione,
            login_operazione,
            ente_proprietario_id
          )
          (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,                     -- movgest_ts_b_id
                 detmodAcc.movgest_ts_id movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 sum(rmodAcc.movgest_ts_det_mod_importo)  importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_r_movgest_ts_det_mod rmodAcc,
                     siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                     siac_t_modifica modAcc
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   detmodAcc.movgest_ts_det_mod_id=rmodAcc.movgest_ts_det_mod_entrata_id
                and   rsmodAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
                and   rsmodAcc.mod_stato_id=modstato.mod_stato_id
                and   modAcc.mod_id=rsmodAcc.mod_id
                and   modAcc.mod_tipo_id=mod.mod_tipo_id
                and   modAcc.elab_ror_reanno = FALSE
                and   detmodAcc.mtdm_reimputazione_anno is not null
                and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   detmodAcc.mtdm_reimputazione_flag is true
                and   not exists
                (
                select 1
                from siac_r_movgest_ts rts
                where rts.movgest_ts_b_id=ts.movgest_ts_id
                and   rts.movgest_ts_a_id=detmodAcc.movgest_ts_id
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                and   rsmodAcc.data_cancellazione is null
                and   rsmodAcc.validita_fine is null
                and   detmodAcc.data_cancellazione is null
                and   detmodAcc.validita_fine is null
                and   modAcc.data_cancellazione is null
                and   modAcc.validita_fine is null
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         detmodAcc.movgest_ts_id
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo A.2.2=%',codResult;
        end if;
      end if; --  faseReimpFpvId is not null */

    end if; -- A fine


    -- 08.06.2020 Sofia Jira siac-7593
    -- mod spesa collegata a mod entrata con squadratura ( importo_mod_spesa!=tot.coll. importo_mod_entrata)
    -- B
    -- si creano impegni reimputati su componente FPV,  tutti i vincoli vengono reimputati a FPV
    -- anche se avevano AAM, accertamento e se non avevano vincolo
    -- quindi so ho creato sia fresco che FPV
    -- collegamento a mod. entrata parziale
    if faseReimpFrescoId is not null or faseReimpFpvId is not null  and
       coalesce(totModCollegAcc,0)!=0 and
       (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))!=0 and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then
           strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                              ||recmovgest.movgest_ts_id::varchar
                              ||' Componente '
                              ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                              ||' ID= '
                              ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                              ||'. Caso B modifica spesa-modifica entrata parte residua non collegata.';

        raise notice 'B strMessaggio=%',strMessaggio;
		codResult:=null;
        insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,                     -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                -- -recmovgest.importoModifica - sum(rmodAcc.movgest_ts_det_mod_importo)  importo_vincolo_new
                 -dettsmod.movgest_Ts_det_importo - coalesce(sum(query_entrata.movgest_ts_det_mod_importo),0)  importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts_det_mod  dettsmod left join
                     (
                     select rmodAcc.movgest_ts_det_mod_spesa_id, coalesce(sum(rmodAcc.movgest_ts_det_mod_importo),0) movgest_ts_det_mod_importo
                     from siac_r_movgest_ts_det_mod rmodAcc,
                          siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                          siac_t_modifica modAcc,siac_d_modifica_stato statoAcc,siac_d_modifica_tipo tipoAcc
                     where statoAcc.ente_proprietario_id=p_enteProprietarioId
                     and   statoAcc.mod_stato_code!='A'
                     and   rsmodAcc.mod_stato_id=statoAcc.mod_stato_id
                     and   detmodAcc.mod_stato_r_id=rsmodAcc.mod_stato_r_id
                     and   modAcc.mod_id=rsmodAcc.mod_id
                     and   modAcc.elab_ror_reanno = FALSE
                     and   detmodAcc.mtdm_reimputazione_anno is not null
                     and   detmodAcc.mtdm_reimputazione_flag is true
                     and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                    -- and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                     and   rmodAcc.movgest_ts_det_mod_entrata_id=detmodAcc.movgest_ts_det_mod_id
                     and   tipoacc.mod_tipo_id=modAcc.mod_tipo_id
                     and   tipoacc.mod_tipo_code=motivo
                     and   rmodAcc.data_cancellazione is null
                     and   rmodAcc.validita_fine is null
                     and   rsmodAcc.data_cancellazione is null
                     and   rsmodAcc.validita_fine is null
                     and   detmodAcc.data_cancellazione is null
                     and   detmodAcc.validita_fine is null
                     and   modAcc.data_cancellazione is null
                     and   modAcc.validita_fine is null
                     group by rmodAcc.movgest_ts_det_mod_spesa_id
                     ) query_entrata on (query_entrata.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id)
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true

                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                group by bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 ts.movgest_ts_id,
                -- recmovgest.importoModifica
                 dettsmod.movgest_Ts_det_importo
               -- having -recmovgest.importoModifica - sum(rmodAcc.movgest_ts_det_mod_importo)!=0
                having -dettsmod.movgest_Ts_det_importo - coalesce(sum(query_entrata.movgest_ts_det_mod_importo),0)!=0
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new, -- -recmovgest.importoModifica-coalesce(totModCollegAcc,0), -- vincolo nuovo per la quota di differenza
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo B=%',codResult;
	end if;


    -- 08.06.2020 Sofia Jira siac-7593
    -- mod spesa non collegata a mod entrata
    -- in questo caso tutto come prima di questa jira
    -- C
    -- si creano impegni reimputati su componente FPV,  tutti i vincoli vengono reimputati a FPV
    -- anche se avevano AAM, accertamento e se non avevano vincolo
    if faseReimpFrescoId is null and faseReimpFpvId is not null  and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then
       strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso C modfica spesa-modifica entrata non collegata.';
        raise notice 'C strMessaggio=%',strMessaggio;
		codResult:=null;
       insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,  -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 (case when coalesce(sum(abs(rvinc.importo_delta)),0)!=0 then
                            coalesce(sum(abs(rvinc.importo_delta)),0)
                       else abs(dettsmod.movgest_ts_det_importo) end ) -- se non esiste neanche un vincolo lo crea per importo della modifica
                  importo_vincolo_new -- importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts ts,
                     siac_t_modifica mod
                      left join  siac_r_modifica_vincolo rvinc -- se non esiste neanche un vincolo lo crea per importo della modifica
                           join  siac_r_movgest_ts rr
                           on (rr.movgest_ts_r_id=rvinc.movgest_ts_r_id
                               and rr.data_cancellazione is null
                               and rr.validita_fine is null )
                      on (rvinc.mod_id=mod.mod_id and rvinc.modvinc_tipo_operazione='INSERIMENTO'
                         and rvinc.data_cancellazione is null
                         and rvinc.validita_fine is null)
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rModAcc
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         dettsmod.movgest_ts_det_importo
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'Inserimeno quota vincolo B=%',codResult;
	end if;

    -- 08.06.2020 Sofia Jira siac-7593 - fine

/*  09.06.2020 Sofia SIAC-7593 - commentato tutta la parte di vincoli precedentemente implementata

    /* 31.01.2018 Sofia siac-5788 -
       inserimento in fase_bil_t_reimputazione_vincoli per traccia delle modifiche legata a vincoli
       con predisposizione dei dati utili per il successivo job di elaborazione dei vincoli riaccertati
    */
    if codResult is not null  and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then

        /* caso 1
   	       se il vincolo abbattuto era del tipo FPV ->
           creare analogo vincolo nel nuovo bilancio per la quote di vincolo
           abbattuta */
    	strMessaggio := 'Inserimento caso 1 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;
        -- 23.03.2018 Sofia dopo elaborazione riacc_vincoli su CMTO
		-- per bugprod : aggiungere condizione su
        -- anno_reimputazione e tipo_modifica presi da recmovgest
        -- recmovgest.mtdm_reimputazione_anno
        -- recmovgest.mod_tipo_code
        -- si dovrebbe raggruppare e totalizzare ma su questa tabella nn si puo per il mod_id
        -- quindi bisogna poi modificare la logica nella creazione dei vincoli totalizzando
        -- per recmovgest.mtdm_reimputazione_anno
        -- recmovgest.mod_tipo_code ovvero per movimento reimputato
        -- controllare poi anche le altre casistiche
		-- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	    insert into   fase_bil_t_reimputazione_vincoli
		(
			reimputazione_id,
		    fasebilelabid,
		    bil_id,
		    mod_id,
            mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
            reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
		    movgest_ts_r_id,
		    movgest_ts_b_id,
		    avav_id,
		    importo_vincolo,
		    avav_new_id,
		    importo_vincolo_new,
		    data_creazione,
		    login_operazione,
		    ente_proprietario_id
		)
		(select
		 codResult,
		 p_faseBilElabId,
		 bil.bil_id,
		 mod.mod_id,
         tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
         dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
		 rvinc.movgest_ts_r_id,
		 ts.movgest_ts_id, -- movgest_ts_b_id
		 av.avav_id,
		 rts.movgest_ts_importo,
		 avnew.avav_id,       -- avav_new_id
		 abs(rvinc.importo_delta), -- importo_vincolo_new
		 clock_timestamp(),
		 p_loginoperazione,
		 p_enteProprietarioId
		from siac_t_bil bil ,
		     siac_t_periodo per,
		     siac_t_movgest mov,siac_d_movgest_tipo tipo,
		     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
			 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
			 siac_t_movgest_ts_det_mod  dettsmod,
			 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
			 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
			 siac_r_modifica_vincolo rvinc,
		     siac_r_movgest_ts rts,
		     siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav,
		     siac_t_avanzovincolo avnew
		where bil.ente_proprietario_id=p_enteProprietarioId
		and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--		and   per.anno::integer=p_annoBilancio-1
        and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
		and   tipo.ente_proprietario_id=bil.ente_proprietario_id
		and   tipo.movgest_tipo_code=p_movgest_tipo_code
		and   mov.movgest_tipo_id=tipo.movgest_tipo_id
		and   mov.bil_id=bil.bil_id
		and   ts.movgest_id=mov.movgest_id
		and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
		and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
		and   detts.movgest_ts_id=ts.movgest_ts_id
		and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
		and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
		and   dettsmod.movgest_ts_det_importo<0
		and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
		and   modstato.mod_stato_id=rmodstato.mod_stato_id
		and   modstato.mod_stato_code='V'
		and   mod.mod_id=rmodstato.mod_id
		and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
		and   rvinc.mod_id=mod.mod_id
		and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
		and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
		and   av.avav_id=rts.avav_id
		and   tipoav.avav_tipo_id=av.avav_tipo_id
		and   tipoav.avav_tipo_code in ('FPVCC','FPVSC')
		and   avnew.avav_tipo_id=tipoav.avav_tipo_id
		and   extract('year' from avnew.validita_inizio::timestamp)::integer=p_annoBilancio
		and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
		and   dettsmod.mtdm_reimputazione_flag is true
		and   rmodstato.validita_fine is null
		and   mov.data_cancellazione is null
		and   mov.validita_fine is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   detts.data_cancellazione is null
		and   detts.validita_fine is null
		and   dettsmod.data_cancellazione is null
		and   dettsmod.validita_fine is null
		and   rmodstato.data_cancellazione is null
		and   rmodstato.validita_fine is null
		and   mod.data_cancellazione is null
		and   mod.validita_fine is null
		and   rvinc.data_cancellazione is null
		and   rvinc.validita_fine is null
		and   rts.data_cancellazione is null
		and   rts.validita_fine is null
	   );

    	strMessaggio := 'Inserimento caso 2 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

	  /* caso 2
		 se il vincolo abbattuto era del tipo Avanzo -> creare un vincolo nel nuovo bilancio di tipo FPV
		 per la quote di vincolo abbattuta con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno
		 (vedi algoritmo a seguire) */
	  -- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	  insert into   fase_bil_t_reimputazione_vincoli
	  (
		reimputazione_id,
    	fasebilelabid,
	    bil_id,
    	mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
	    movgest_ts_r_id,
	    movgest_ts_b_id,
	    avav_id,
	    importo_vincolo,
	    avav_new_id,
	    importo_vincolo_new,
	    data_creazione,
	    login_operazione,
    	ente_proprietario_id
	   )
	   (
		with
		titoloNew as
	    (
    	  	select cTitolo.classif_code::integer titolo_uscita,
        	       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
	        from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
    	         siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
        	     siac_r_class_fam_tree rfam,
            	 siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
	             siac_t_bil bil, siac_t_periodo per
    	    where tipo.ente_proprietario_id=p_enteProprietarioId
	        and   tipo.elem_tipo_code=CAP_UG_TIPO
	        and   e.elem_tipo_id=tipo.elem_tipo_id
    	    and   bil.bil_id=e.bil_id
	        and   per.periodo_id=bil.periodo_id
	        and   per.anno::integer=p_annoBilancio
	        and   e.elem_code::integer=recmovgest.elem_code::integer
	        and   e.elem_code2::integer=recmovgest.elem_code2::integer
	        and   e.elem_code3=recmovgest.elem_code3
	        and   rc.elem_id=e.elem_id
	        and   cMacro.classif_id=rc.classif_id
	        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
	        and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
	        and   rfam.classif_id=cMacro.classif_id
	        and   cTitolo.classif_id=rfam.classif_id_padre
	        and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
    	    and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
	        and   e.data_cancellazione is null
	        and   e.validita_fine is null
	        and   rc.data_cancellazione is null
	        and   rc.validita_fine is null
	        and   rfam.data_cancellazione is null
	        and   rfam.validita_fine is null
	   ),
	   avanzoTipo as
   	   (
		 select av.avav_id, avtipo.avav_tipo_code
		 from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
		 where avtipo.ente_proprietario_id=p_enteProprietarioId
		 and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
		 and   av.avav_tipo_id=avtipo.avav_tipo_id
	     and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
	   ),
	   vincPrec as
	   (
		select
		 bil.bil_id,
		 mod.mod_id,
         tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
         dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
		 rvinc.movgest_ts_r_id,
		 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
		 av.avav_id,
		 rts.movgest_ts_importo importo_vincolo,
		 abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
		from siac_t_bil bil ,
		     siac_t_periodo per,
		     siac_t_movgest mov,siac_d_movgest_tipo tipo,
		     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
			 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
			 siac_t_movgest_ts_det_mod  dettsmod,
			 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
			 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
			 siac_r_modifica_vincolo rvinc,
		     siac_r_movgest_ts rts,
		     siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav
		where bil.ente_proprietario_id=p_enteProprietarioId
		and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--		and   per.anno::integer=p_annoBilancio-1
        and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
        and   tipo.ente_proprietario_id=bil.ente_proprietario_id
		and   tipo.movgest_tipo_code=p_movgest_tipo_code
		and   mov.movgest_tipo_id=tipo.movgest_tipo_id
		and   mov.bil_id=bil.bil_id
		and   ts.movgest_id=mov.movgest_id
		and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
		and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
		and   detts.movgest_ts_id=ts.movgest_ts_id
		and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
		and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
		and   dettsmod.movgest_ts_det_importo<0
		and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
		and   modstato.mod_stato_id=rmodstato.mod_stato_id
		and   modstato.mod_stato_code='V'
		and   mod.mod_id=rmodstato.mod_id
		and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
		and   rvinc.mod_id=mod.mod_id
		and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
		and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
		and   av.avav_id=rts.avav_id
		and   tipoav.avav_tipo_id=av.avav_tipo_id
		and   tipoav.avav_tipo_code  ='AAM'
		and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
		and   dettsmod.mtdm_reimputazione_flag is true
		and   rmodstato.validita_fine is null
		and   mov.data_cancellazione is null
		and   mov.validita_fine is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   detts.data_cancellazione is null
		and   detts.validita_fine is null
		and   dettsmod.data_cancellazione is null
		and   dettsmod.validita_fine is null
		and   rmodstato.data_cancellazione is null
		and   rmodstato.validita_fine is null
		and   mod.data_cancellazione is null
		and   mod.validita_fine is null
		and   rvinc.data_cancellazione is null
		and   rvinc.validita_fine is null
		and   rts.data_cancellazione is null
		and   rts.validita_fine is null
	 )
	  select codResult,
	 	     p_faseBilElabId,
	         vincPrec.bil_id,
    	     vincPrec.mod_id,
             vincPrec.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             vincPrec.mtdm_reimputazione_anno,  -- 06.04.2018 Sofia JIRA SIAC-6054
	         vincPrec.movgest_ts_r_id,
	         vincPrec.movgest_ts_b_id,
    	     vincPrec.avav_id,
	         vincPrec.importo_vincolo,
	         avanzoTipo.avav_id,
	         vincPrec.importo_vincolo_new,
	         clock_timestamp(),
	         p_loginoperazione,
	         p_enteProprietarioId
	  from vincPrec,titoloNew,avanzoTipo
	  where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
      );

    	strMessaggio := 'Inserimento caso 3,4 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

      /* caso 3
  		 se il vincolo abbattuto era legato ad un accertamento
		 che non presenta quote riaccertate esso stesso:
		 creare un vincolo nel nuovo bilancio di tipo FPV per la quote di vincolo abbattuta
		 con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno (vedi algoritmo a seguire)*/

	  /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
      -- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	  insert into   fase_bil_t_reimputazione_vincoli
  	  (
		reimputazione_id,
	    fasebilelabid,
    	bil_id,
	    mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
    	movgest_ts_r_id,
	    movgest_ts_b_id,
    	movgest_ts_a_id,
	    importo_vincolo,
    	avav_new_id,
	    importo_vincolo_new,
    	data_creazione,
	    login_operazione,
    	ente_proprietario_id
	 )
     (
		with
		titoloNew as
        (
  	    	select cTitolo.classif_code::integer titolo_uscita,
    	           ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        	from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
            	 siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
	             siac_r_class_fam_tree rfam,
    	         siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
        	     siac_t_bil bil, siac_t_periodo per
	        where tipo.ente_proprietario_id=p_enteProprietarioId
    	    and   tipo.elem_tipo_code=CAP_UG_TIPO
	        and   e.elem_tipo_id=tipo.elem_tipo_id
    	    and   bil.bil_id=e.bil_id
	        and   per.periodo_id=bil.periodo_id
	        and   per.anno::integer=p_annoBilancio
    	    and   e.elem_code::integer=recmovgest.elem_code::integer
	        and   e.elem_code2::integer=recmovgest.elem_code2::integer
    	    and   e.elem_code3::integer=recmovgest.elem_code3::integer
	        and   rc.elem_id=e.elem_id
    	    and   cMacro.classif_id=rc.classif_id
	        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
    	    and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
        	and   rfam.classif_id=cMacro.classif_id
	        and   cTitolo.classif_id=rfam.classif_id_padre
    	    and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        	and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
	        and   e.data_cancellazione is null
    	    and   e.validita_fine is null
        	and   rc.data_cancellazione is null
	        and   rc.validita_fine is null
    	    and   rfam.data_cancellazione is null
	        and   rfam.validita_fine is null
		),
		avanzoTipo as
		(
			select av.avav_id, avtipo.avav_tipo_code
			from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
			where avtipo.ente_proprietario_id=p_enteProprietarioId
			and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
			and   av.avav_tipo_id=avtipo.avav_tipo_id
			and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
		),
		vincPrec as
		(
			select
			 bil.bil_id,
			 mod.mod_id,
             tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
			 rvinc.movgest_ts_r_id,
			 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
			 rts.movgest_ts_a_id,              -- movgest_ts_a_id
			 rts.movgest_ts_importo importo_vincolo,
			 abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
			from siac_t_bil bil ,
			     siac_t_periodo per,
			     siac_t_movgest mov,siac_d_movgest_tipo tipo,
			     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
				 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
				 siac_t_movgest_ts_det_mod  dettsmod,
				 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
				 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
				 siac_r_modifica_vincolo rvinc,
			     siac_r_movgest_ts rts
			where bil.ente_proprietario_id=p_enteProprietarioId
			and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--			and   per.anno::integer=p_annoBilancio-1
            and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
			and   tipo.ente_proprietario_id=bil.ente_proprietario_id
			and   tipo.movgest_tipo_code=p_movgest_tipo_code
			and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			and   mov.bil_id=bil.bil_id
			and   ts.movgest_id=mov.movgest_id
			and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
			and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			and   detts.movgest_ts_id=ts.movgest_ts_id
			and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
			and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
			and   dettsmod.movgest_ts_det_importo<0
			and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
			and   modstato.mod_stato_id=rmodstato.mod_stato_id
			and   modstato.mod_stato_code='V'
			and   mod.mod_id=rmodstato.mod_id
			and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
            and   mod.elab_ror_reanno = FALSE
            and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
            and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   rts.movgest_ts_a_id is not null -- legato ad accertamento
			and   dettsmod.mtdm_reimputazione_anno is not null
            and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
			and   dettsmod.mtdm_reimputazione_flag is true
			and   rmodstato.validita_fine is null
			and   mov.data_cancellazione is null
			and   mov.validita_fine is null
			and   ts.data_cancellazione is null
			and   ts.validita_fine is null
			and   detts.data_cancellazione is null
			and   detts.validita_fine is null
			and   dettsmod.data_cancellazione is null
			and   dettsmod.validita_fine is null
			and   rmodstato.data_cancellazione is null
			and   rmodstato.validita_fine is null
			and   mod.data_cancellazione is null
			and   mod.validita_fine is null
			and   rvinc.data_cancellazione is null
			and   rvinc.validita_fine is null
			and   rts.data_cancellazione is null
			and   rts.validita_fine is null
		)
		select codResult,
	    	   p_faseBilElabId,
	           vincPrec.bil_id,
	  	       vincPrec.mod_id,
               vincPrec.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
               vincPrec.mtdm_reimputazione_anno,  -- 06.04.2018 Sofia JIRA SIAC-6054
	  	   	   vincPrec.movgest_ts_r_id,
	           vincPrec.movgest_ts_b_id,
	  	       vincPrec.movgest_ts_a_id,
	      	   vincPrec.importo_vincolo,
	           avanzoTipo.avav_id,
	           vincPrec.importo_vincolo_new,
	           clock_timestamp(),
	           p_loginoperazione,
       	       p_enteProprietarioId
        from vincPrec,titoloNew,avanzoTipo
		where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
	   );


       /* gestione scarti
       */
    	strMessaggio := 'Inserimento scarti in in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

       insert into   fase_bil_t_reimputazione_vincoli
  	  (
		reimputazione_id,
	    fasebilelabid,
    	bil_id,
	    mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
    	movgest_ts_r_id,
	    movgest_ts_b_id,
    	movgest_ts_a_id,
	    importo_vincolo,
	    importo_vincolo_new,
        scarto_code,
        scarto_desc,
    	data_creazione,
	    login_operazione,
    	ente_proprietario_id
	 )
     (
			select
             codResult,
             p_faseBilElabId,
			 bil.bil_id,
			 mod.mod_id,
             tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
			 rvinc.movgest_ts_r_id,
			 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
			 rts.movgest_ts_a_id,              -- movgest_ts_a_id
			 rts.movgest_ts_importo,  -- importo_vincolo
			 abs(rvinc.importo_delta), -- importo_vincolo_new
             '99',
             'VINCOLO NON CLASSIFICATO',
             clock_timestamp(),
             p_loginoperazione,
     	     p_enteProprietarioId
			from siac_t_bil bil ,
			     siac_t_periodo per,
			     siac_t_movgest mov,siac_d_movgest_tipo tipo,
			     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
				 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
				 siac_t_movgest_ts_det_mod  dettsmod,
				 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
				 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
				 siac_r_modifica_vincolo rvinc,
			     siac_r_movgest_ts rts
			where bil.ente_proprietario_id=p_enteProprietarioId
			and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--			and   per.anno::integer=p_annoBilancio-1
            and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
			and   tipo.ente_proprietario_id=bil.ente_proprietario_id
			and   tipo.movgest_tipo_code=p_movgest_tipo_code
			and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			and   mov.bil_id=bil.bil_id
			and   ts.movgest_id=mov.movgest_id
			and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
			and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			and   detts.movgest_ts_id=ts.movgest_ts_id
			and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
			and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
			and   dettsmod.movgest_ts_det_importo<0
			and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
			and   modstato.mod_stato_id=rmodstato.mod_stato_id
			and   modstato.mod_stato_code='V'
			and   mod.mod_id=rmodstato.mod_id
			and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
            and   mod.elab_ror_reanno = FALSE
            and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
            and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   dettsmod.mtdm_reimputazione_anno is not null
            and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
			and   dettsmod.mtdm_reimputazione_flag is true
            and   not exists
            (
            select 1
            from fase_bil_t_reimputazione_vincoli fase
            where fase.fasebilelabid=p_faseBilElabId
            and   fase.movgest_ts_r_id=rts.movgest_ts_r_id
            and   fase.movgest_ts_b_id=ts.movgest_ts_id
            and   fase.mod_tipo_code=recmovgest.mod_tipo_code -- 06.04.2018 Sofia JIRA SIAC-6054
            and   fase.reimputazione_anno=recmovgest.mtdm_reimputazione_anno::integer -- 06.04.2018 Sofia JIRA SIAC-6054
            )
			and   rmodstato.validita_fine is null
			and   mov.data_cancellazione is null
			and   mov.validita_fine is null
			and   ts.data_cancellazione is null
			and   ts.validita_fine is null
			and   detts.data_cancellazione is null
			and   detts.validita_fine is null
			and   dettsmod.data_cancellazione is null
			and   dettsmod.validita_fine is null
			and   rmodstato.data_cancellazione is null
			and   rmodstato.validita_fine is null
			and   mod.data_cancellazione is null
			and   mod.validita_fine is null
			and   rvinc.data_cancellazione is null
			and   rvinc.validita_fine is null
			and   rts.data_cancellazione is null
			and   rts.validita_fine is null
	   );


    end if;
09.06.2020 Sofia SIAC-7593 - fine */



    end loop;

    strMessaggio := 'fine del loop';

    outfaseBilElabRetId:=p_faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_elabora(
	p_fasebilelabid integer,
	enteproprietarioid integer,
	annobilancio integer,
	impostaprovvedimento boolean,
	loginoperazione character varying,
	dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying)
RETURNS record
AS $body$

  DECLARE
    strmessaggiotemp   				VARCHAR(1000):='';
    tipomovgestid      				INTEGER:=NULL;
    movgesttstipoid    				INTEGER:=NULL;
    tipomovgesttssid   				INTEGER:=NULL;
    tipomovgesttstid   				INTEGER:=NULL;
    tipocapitologestid 				INTEGER:=NULL;
    bilancioid         				INTEGER:=NULL;
    bilancioprecid     				INTEGER:=NULL;
    periodoid          				INTEGER:=NULL;
    periodoprecid      				INTEGER:=NULL;
    datainizioval      				timestamp:=NULL;
    movgestidret      				INTEGER:=NULL;
    movgesttsidret    				INTEGER:=NULL;
    v_elemid          				INTEGER:=NULL;
    movgesttstipotid  				INTEGER:=NULL;
    movgesttstiposid  				INTEGER:=NULL;
    movgesttstipocode 				VARCHAR(10):=NULL;
    movgeststatoaid   				INTEGER:=NULL;
    v_importomodifica 				NUMERIC;
    movgestrec 						RECORD;
    aggprogressivi 					RECORD;
    cleanrec						RECORD;
    v_movgest_numero                INTEGER;
    v_prog_id                       INTEGER;
    v_flagdariaccertamento_attr_id  INTEGER;
    v_annoriaccertato_attr_id       INTEGER;
    v_numeroriaccertato_attr_id     INTEGER;
    v_numero_el                     integer;
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo        CONSTANT VARCHAR:='BIL_ORD';
    imp_movgest_tipo    CONSTANT VARCHAR:='I';
    acc_movgest_tipo    CONSTANT VARCHAR:='A';
    sim_movgest_ts_tipo CONSTANT VARCHAR:='SIM';
    sac_movgest_ts_tipo CONSTANT VARCHAR:='SAC';
    a_mov_gest_stato    CONSTANT VARCHAR:='A';
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    codresult           INTEGER;
    v_bil_attr_id       INTEGER;
    v_attr_code         VARCHAR;
    movgest_ts_t_tipo   CONSTANT VARCHAR:='T';
    movgest_ts_s_tipo   CONSTANT VARCHAR:='S';
    cap_ug_tipo         CONSTANT VARCHAR:='CAP-UG';
    cap_eg_tipo         CONSTANT VARCHAR:='CAP-EG';
    ape_gest_reimp      CONSTANT VARCHAR:='APE_GEST_REIMP';
    faserec RECORD;
    faseelabrec RECORD;
    recmovgest RECORD;
    v_maxcodgest      INTEGER;
    v_movgest_ts_id   INTEGER;
    v_ambito_id       INTEGER;
    v_inizio          VARCHAR;
    v_fine            VARCHAR;
    v_bil_tipo_id     INTEGER;
    v_periodo_id      INTEGER;
    v_periodo_tipo_id INTEGER;
    v_tmp             VARCHAR;


    -- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;
-- SIAC-6997 ---------------- INIZIO --------------------
	DAREANNO_ATTR CONSTANT varchar:='flagDaReanno';
    v_flagdareanno_attr_id  integer:=null;
-- SIAC-6997 ---------------- FINE --------------------
	-- 07.03.2017 Sofia SIAC-4568
    dataEmissione     timestamp:=null;

	-- 07.02.2018 Sofia siac-5368
    movGestStatoId INTEGER:=null;
    movGestStatoPId INTEGER:=null;
	MOVGEST_STATO_CODE_P CONSTANT VARCHAR:='P';

  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio.';
    datainizioval:= clock_timestamp();
    -- 07.03.2017 Sofia SIAC-4568
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;

    SELECT attr.attr_id
    INTO   v_flagdariaccertamento_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='flagDaRiaccertamento'
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- INIZIO --------------------

    SELECT attr.attr_id
    INTO   v_flagdareanno_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code = DAREANNO_ATTR
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- FINE --------------------

    SELECT attr.attr_id
    INTO   v_annoriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='annoRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_numeroriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='numeroRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    -- estraggo il bilancio nuovo
    SELECT bil_id
    INTO   strict bilancioid
    FROM   siac_t_bil
    WHERE  bil_code = 'BIL_'
                  ||annobilancio::VARCHAR
    AND    ente_proprietario_id = enteproprietarioid;

	-- 07.02.2018 Sofia siac-5368
    strMessaggio:='Lettura identificativo per stato='||MOVGEST_STATO_CODE_P||'.';
	select stato.movgest_stato_id
    into   strict movGestStatoPId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteproprietarioid
    and   stato.movgest_stato_code=MOVGEST_STATO_CODE_P;

    -- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo then
    	strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTipoCode='||imp_movgest_tipo||'.';
        select tipo.movgest_tipo_id into strict tipoMovGestId
        from siac_d_movgest_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_tipo_code=imp_movgest_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTsTTipoCode='||movgest_ts_t_tipo||'.';
        select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
        from siac_d_movgest_ts_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_ts_tipo_code=movgest_ts_t_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

    end if;


    FOR movgestrec IN
    (
           SELECT reimputazione_id ,
                  bil_id ,
                  elemid_old ,
                  elem_code ,
                  elem_code2 ,
                  elem_code3 ,
                  elem_tipo_code ,
                  movgest_id ,
                  movgest_anno ,
                  movgest_numero ,
                  movgest_desc ,
                  movgest_tipo_id ,
                  parere_finanziario ,
                  parere_finanziario_data_modifica ,
                  parere_finanziario_login_operazione ,
                  movgest_ts_id ,
                  movgest_ts_code ,
                  movgest_ts_desc ,
                  movgest_ts_tipo_id ,
                  movgest_ts_id_padre ,
                  ordine ,
                  livello ,
                  movgest_ts_scadenza_data ,
                  movgest_ts_det_tipo_id ,
                  impoinizimpegno ,
                  impoattimpegno ,
                  importomodifica ,
                  tipo ,
                  movgest_ts_det_tipo_code ,
                  movgest_ts_det_importo ,
                  mtdm_reimputazione_anno ,
                  mtdm_reimputazione_flag ,
                  mod_tipo_code ,
                  attoamm_id,       -- 07.02.2018 Sofia siac-5368
                  movgest_stato_id, -- 07.02.2018 Sofia siac-5368
                  importo_reimputato, -- 05.06.2020 Sofia SIAC-7593
                  importo_modifica_entrata, -- 05.06.2020 Sofia SIAC-7593
                  coll_mod_entrata,  -- 05.06.2020 Sofia SIAC-7593
                  elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N'
           order by  1) -- 19.04.2019 Sofia JIRA SIAC-6788
    LOOP
      movgesttsidret:=NULL;
      movgestidret:=NULL;
      codresult:=NULL;
      v_elemid:=NULL;
      v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-01-01';
      v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-12-31';

	  --caso in cui si tratta di impegno/ accertamento creo la struttua a partire da movgest
      --tipots.movgest_ts_tipo_code tipo

      IF movgestrec.tipo !='S' THEN

        v_movgest_ts_id = NULL;
        --v_maxcodgest= movgestrec.movgest_ts_code::INTEGER;

        IF p_movgest_tipo_code = 'I' THEN
          strmessaggio:='progressivo per Impegno ' ||'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
          SELECT prog_value + 1 ,
                 prog_id
          INTO   strict v_movgest_numero ,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN
            strmessaggio:='aggiungo progressivo per anno ' ||'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   strict v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            INSERT INTO siac_t_progressivo
            (
                        prog_value,
                        prog_key ,
                        ambito_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_cancellazione ,
                        login_operazione
            )
            VALUES
            (
                        0,
                        'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
                        v_ambito_id ,
                        v_inizio::timestamp,
                        v_fine::timestamp,
                        enteproprietarioid ,
                        NULL,
                        loginoperazione
            )
            returning   prog_id  INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF;

        ELSE --IF p_movgest_tipo_code = 'I'

          --Accertamento
          SELECT prog_value + 1,
                 prog_id
          INTO   v_movgest_numero,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN

            strmessaggio:='aggiungo progressivo per anno ' ||'acc_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-01-01'; v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-12-31';
            INSERT INTO siac_t_progressivo
			(
				prog_value ,
				prog_key ,
				ambito_id ,
				validita_inizio ,
				validita_fine ,
				ente_proprietario_id ,
				data_cancellazione ,
				login_operazione
			)
			VALUES
			(
				0,
				'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
				v_ambito_id ,
				v_inizio::timestamp,
				v_fine::timestamp,
				enteproprietarioid ,
				NULL,
				loginoperazione
			)
            returning   prog_id INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   strict v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF; --fine if v_movgest_numero

        END IF;

        strmessaggio:='inserisco il siac_t_movgest.';
        INSERT INTO siac_t_movgest
        (
			movgest_anno,
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
        VALUES
        (
			movgestrec.mtdm_reimputazione_anno,
            v_movgest_numero,
			movgestrec.movgest_desc,
			movgestrec.movgest_tipo_id,
			bilancioid,
			datainizioval,
			enteproprietarioid,
			loginoperazione,
			movgestrec.parere_finanziario,
			movgestrec.parere_finanziario_data_modifica,
			movgestrec.parere_finanziario_login_operazione
        )
        returning   movgest_id INTO        movgestidret;

        IF movgestidret IS NULL THEN
          strmessaggiotemp:=strmessaggio;
          codresult:=-1;
        END IF;

        RAISE notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movgestidret;

        strmessaggio:='aggiornamento progressivo v_prog_id ' ||v_prog_id::VARCHAR;
        UPDATE siac_t_progressivo
        SET    prog_value = prog_value + 1
        WHERE  prog_id = v_prog_id;

        strmessaggio:='estraggo il capitolo =elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';
        --raise notice 'strMessaggio=%',strMessaggio;
        SELECT be.elem_id
        INTO   v_elemid
        FROM   siac_t_bil_elem be,
               siac_r_bil_elem_stato rbes,
               siac_d_bil_elem_stato bbes,
               siac_d_bil_elem_tipo bet
        WHERE  be.elem_tipo_id = bet.elem_tipo_id
        AND    be.elem_code=movgestrec.elem_code
        AND    be.elem_code2=movgestrec.elem_code2
        AND    be.elem_code3=movgestrec.elem_code3
        AND    bet.elem_tipo_code = movgestrec.elem_tipo_code
        AND    be.elem_id = rbes.elem_id
        AND    rbes.elem_stato_id = bbes.elem_stato_id
        AND    bbes.elem_stato_code !='AN'
        AND    rbes.data_cancellazione IS NULL
        AND    be.bil_id = bilancioid
        AND    be.ente_proprietario_id = enteproprietarioid
        AND    be.data_cancellazione IS NULL
        AND    be.validita_fine IS NULL;

        IF v_elemid IS NULL THEN
          codresult:=-1;
          strmessaggio:= ' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';

          update fase_bil_t_reimputazione
          set fl_elab='X'
            ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
            ,scarto_code='IMAC1'
            ,scarto_desc=' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.'
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
          continue;
        END IF;


        -- relazione tra capitolo e movimento
        strmessaggio:='Inserimento relazione movimento capitolo anno='||movgestrec.movgest_anno ||' numero=' ||movgestrec.movgest_numero || ' v_elemId='||v_elemid::varchar ||' [siac_r_movgest_bil_elem]';

        INSERT INTO siac_r_movgest_bil_elem
        (
          movgest_id,
          elem_id,
          elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          -- 05.06.2020 Sofia SIAC-7593
          (case when p_movgest_tipo_code='I' then movgestrec.elem_det_comp_tipo_id else null end ),
          datainizioval,
          enteproprietarioid,
          loginoperazione
        )
        returning   movgest_atto_amm_id  INTO        codresult;

        IF codresult IS NULL THEN
          codresult:=-1;
          strmessaggiotemp:=strmessaggio;
        ELSE
          codresult:=NULL;
        END IF;
        strmessaggio:='Inserimento movimento movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' sub=' ||movgestrec.movgest_ts_code || ' [siac_t_movgest_ts].';
        RAISE notice 'strMessaggio=% ',strmessaggio;

        v_maxcodgest := v_movgest_numero;



      ELSE --caso in cui si tratta di subimpegno/ subaccertamento estraggo il movgest_id padre e movgest_ts_id_padre IF movgestrec.tipo =='S'

        -- todo calcolare il papa' sel subimpegno movgest_id  del padre  ed anche movgest_ts_id_padre
        strmessaggio:='caso SUB movGestTipo=' ||movgestrec.tipo ||'.';

        SELECT count(*)
        INTO v_numero_el
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
       and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
                     then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id
                     else p_movgest_tipo_code='A' end);

      --  raise notice 'strMessaggio anno=% numero=% v_numero_el=%', movgestrec.movgest_anno, movgestrec.movgest_numero,v_numero_el;

        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
	    and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
                     then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id
                     else p_movgest_tipo_code='A' end);


        if movgestidret is null then
          update fase_bil_t_reimputazione
          set fl_elab        ='X'
            ,scarto_code      ='IMACNP'
            ,scarto_desc      =' subimpegno/subaccertamento privo di testata modificata movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' v_numero_el = ' ||v_numero_el::varchar||'.'
      	    ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
          from
          	siac_t_bil_elem elem
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
        	continue;
        end if;


        strmessaggio:=' estraggo movGest padre movGestRec.movgest_id='||movgestrec.movgest_id::VARCHAR ||' p_fasebilelabid'||p_fasebilelabid::VARCHAR ||'' ||'.';
        --strMessaggio:='calcolo il max siac_t_movgest_ts.movgest_ts_code  movGestIdRet='||movGestIdRet::varchar ||'.';

        SELECT max(siac_t_movgest_ts.movgest_ts_code::INTEGER)
        INTO   v_maxcodgest
        FROM   siac_t_movgest ,
               siac_t_movgest_ts ,
               siac_d_movgest_tipo,
               siac_d_movgest_ts_tipo
        WHERE  siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id
        AND    siac_t_movgest.movgest_tipo_id = siac_d_movgest_tipo.movgest_tipo_id
        AND    siac_d_movgest_tipo.movgest_tipo_code = p_movgest_tipo_code
        AND    siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id
        AND    siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'S'
        AND    siac_t_movgest.bil_id = bilancioid
        AND    siac_t_movgest.ente_proprietario_id = enteproprietarioid
        AND    siac_t_movgest.movgest_id = movgestidret;

        IF v_maxcodgest IS NULL THEN
          v_maxcodgest:=0;
        END IF;
        v_maxcodgest := v_maxcodgest+1;

     END IF; -- fine cond se sub o non sub





      -- caso di sub



      INSERT INTO siac_t_movgest_ts
      (
        movgest_ts_code,
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
      VALUES
      (
        v_maxcodgest::VARCHAR, --movGestRec.movgest_ts_code,
        movgestrec.movgest_ts_desc,
        movgestidret, -- inserito se I/A, per SUB ricavato
        movgestrec.movgest_ts_tipo_id,
        v_movgest_ts_id, -- ????? valorizzato se SUB come quello da cui deriva diversamente null
        movgestrec.movgest_ts_scadenza_data,
        movgestrec.ordine,
        movgestrec.livello,
--        dataelaborazione, -- 07.03.2017 Sofia SIAC-4568
		dataEmissione,      -- 07.03.2017 Sofia SIAC-4568
        enteproprietarioid,
        loginoperazione,
        loginoperazione,
        movgestrec.siope_tipo_debito_id,
		movgestrec.siope_assenza_motivazione_id
      )
      returning   movgest_ts_id
      INTO        movgesttsidret;

      IF movgesttsidret IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      END IF;
      RAISE notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movgesttsidret,codresult;

      -- siac_r_movgest_ts_stato
      strmessaggio:='Inserimento movimento ' || ' anno='  ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code || ' [siac_r_movgest_ts_stato].';
      -- 07.02.2018 Sofia siac-5368
      /*INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.movgest_stato_id,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_stato r,
                siac_d_movgest_stato stato
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    stato.movgest_stato_id=r.movgest_stato_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    stato.data_cancellazione IS NULL
         AND    stato.validita_fine IS NULL )
      returning   movgest_stato_r_id INTO        codresult;*/

      -- 07.02.2018 Sofia siac-5368
	  if impostaProvvedimento=true then
      	     movGestStatoId:=movGestRec.movgest_stato_id;
      else   movGestStatoId:=movGestStatoPId;
      end if;

      INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
      values
      (
      	movgesttsidret,
        movGestStatoId,
        datainizioval,
        enteProprietarioId,
        loginoperazione
      )
      returning   movgest_stato_r_id INTO        codresult;


      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      RAISE notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movgesttsidret,codresult;
      -- siac_t_movgest_ts_det
      strmessaggio:='Inserimento movimento ' || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code|| ' [siac_t_movgest_ts_det].';
      RAISE notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_ts_id=%', movgesttsidret,movgestrec.movgest_ts_id;
      -- 05.06.2020 Sofia Jira SIAC-7593
      --v_importomodifica := movgestrec.importomodifica * -1;
      -- 05.06.2020 Sofia Jira SIAC-7593
      v_importomodifica:= movgestrec.importo_reimputato;
      INSERT INTO siac_t_movgest_ts_det
	  (
        movgest_ts_id,
        movgest_ts_det_tipo_id,
        movgest_ts_det_importo,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
       SELECT movgesttsidret,
              r.movgest_ts_det_tipo_id,
              v_importomodifica,
              datainizioval,
              enteproprietarioid,
              loginoperazione
       FROM   siac_t_movgest_ts_det r
       WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
       AND    r.data_cancellazione IS NULL
       AND    r.validita_fine IS NULL );

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      strmessaggio:='Inserimento classificatori  movgest_ts_id='||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_class].';
      -- siac_r_movgest_class
      INSERT INTO siac_r_movgest_class
	  (
				  movgest_ts_id,
				  classif_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.classif_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_class r,
					siac_t_class class
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    class.classif_id=r.classif_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
			 AND    class.data_cancellazione IS NULL
			 AND    class.validita_fine IS NULL );

      strmessaggio:='Inserimento attributi  movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_attr].';
      -- siac_r_movgest_ts_attr
      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id,
        attr_id,
        tabella_id,
        BOOLEAN,
        percentuale,
        testo,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.attr_id,
                r.tabella_id,
                r.BOOLEAN,
                r.percentuale,
                r.testo,
                r.numerico,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_attr r,
                siac_t_attr attr
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    attr.attr_id=r.attr_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    attr.data_cancellazione IS NULL
         AND    attr.validita_fine IS NULL
         AND    attr.attr_code NOT IN ('flagDaRiaccertamento',
                                       'annoRiaccertato',
                                       'numeroRiaccertato',
									   'flagDaReanno') ); -- 02.10.2020 SIAC-7593
									   
-- SIAC-6997 ---------------- INIZIO --------------------
    if motivo = 'REIMP' then
-- SIAC-6997 ---------------- FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdariaccertamento_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
-- SIAC-6997 ---------------- INIZIO --------------------
    else
      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdareanno_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
    end if;
-- SIAC-6997 ----------------  FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_annoriaccertato_attr_id,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_anno ,
        NULL ,
        now() ,
        NULL,
        enteproprietarioid,
        NULL,
        loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_numeroriaccertato_attr_id ,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_numero ,
        NULL,
        now() ,
        NULL ,
        enteproprietarioid ,
        NULL,
        loginoperazione
	  );

      -- siac_r_movgest_ts_atto_amm
      /*strmessaggio:='Inserimento   movgest_ts_id='
      ||movgestrec.movgest_ts_id::VARCHAR
      || ' [siac_r_movgest_ts_atto_amm].';
      INSERT INTO siac_r_movgest_ts_atto_amm
	  (
				  movgest_ts_id,
				  attoamm_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.attoamm_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_atto_amm r,
					siac_t_atto_amm atto
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    atto.attoamm_id=r.attoamm_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
       );*/
--			 AND    atto.data_cancellazione IS NULL Sofia HD-INC000001535447
--			 AND    atto.validita_fine IS NULL );

	   -- 07.02.2018 Sofia siac-5368
	   if impostaProvvedimento=true then
       	strmessaggio:='Inserimento   movgest_ts_id='
	      ||movgestrec.movgest_ts_id::VARCHAR
    	  || ' [siac_r_movgest_ts_atto_amm].';
       	INSERT INTO siac_r_movgest_ts_atto_amm
	  	(
		 movgest_ts_id,
	     attoamm_id,
	     validita_inizio,
	     ente_proprietario_id,
	     login_operazione
	  	)
        values
        (
         movgesttsidret,
         movgestrec.attoamm_id,
         datainizioval,
	 	 enteproprietarioid,
	 	 loginoperazione
        );
       end if;


      -- siac_r_movgest_ts_sog
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sog].';
      INSERT INTO siac_r_movgest_ts_sog
	  (
				  movgest_ts_id,
				  soggetto_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sog r,
					siac_t_soggetto sogg
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sogg.soggetto_id=r.soggetto_id
			 AND    sogg.data_cancellazione IS NULL
			 AND    sogg.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_sogclasse
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sogclasse].';
      INSERT INTO siac_r_movgest_ts_sogclasse
	  (
				  movgest_ts_id,
				  soggetto_classe_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_classe_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sogclasse r,
					siac_d_soggetto_classe classe
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    classe.soggetto_classe_id=r.soggetto_classe_id
			 AND    classe.data_cancellazione IS NULL
			 AND    classe.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_programma
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_programma].';
      INSERT INTO siac_r_movgest_ts_programma
	  (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    prog.programma_id=r.programma_id
			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

     --- 18.06.2019 Sofia SIAC-6702
	 if p_movgest_tipo_code=imp_movgest_tipo then
      -- siac_r_movgest_ts_storico_imp_acc
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_storico_imp_acc].';
      INSERT INTO siac_r_movgest_ts_storico_imp_acc
	  (
			movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.movgest_anno_acc,
             		r.movgest_numero_acc,
		            r.movgest_subnumero_acc,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_storico_imp_acc r
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );
      end if;

      -- siac_r_mutuo_voce_movgest
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_mutuo_voce_movgest].';
      INSERT INTO siac_r_mutuo_voce_movgest
	  (
				  movgest_ts_id,
				  mut_voce_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.mut_voce_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_mutuo_voce_movgest r,
					siac_t_mutuo_voce voce
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    voce.mut_voce_id=r.mut_voce_id
			 AND    voce.data_cancellazione IS NULL
			 AND    voce.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_causale_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_causale_movgest_ts].';
      INSERT INTO siac_r_causale_movgest_ts
	  (
				  movgest_ts_id,
				  caus_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.caus_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_causale_movgest_ts r,
					siac_d_causale caus
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    caus.caus_id=r.caus_id
			 AND    caus.data_cancellazione IS NULL
			 AND    caus.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- 05.05.2017 Sofia HD-INC000001737424
      -- siac_r_subdoc_movgest_ts
      /*
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_subdoc_movgest_ts].';
      INSERT INTO siac_r_subdoc_movgest_ts
	  (
				  movgest_ts_id,
				  subdoc_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.subdoc_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_subdoc_movgest_ts r,
					siac_t_subdoc sub
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sub.subdoc_id=r.subdoc_id
			 AND    sub.data_cancellazione IS NULL
			 AND    sub.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_predoc_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_predoc_movgest_ts].';
      INSERT INTO siac_r_predoc_movgest_ts
                  (
                              movgest_ts_id,
                              predoc_id,
                              validita_inizio,
                              ente_proprietario_id,
                              login_operazione
                  )
                  (
                         SELECT movgesttsidret,
                                r.predoc_id,
                                datainizioval,
                                enteproprietarioid,
                                loginoperazione
                         FROM   siac_r_predoc_movgest_ts r,
                                siac_t_predoc sub
                         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
                         AND    sub.predoc_id=r.predoc_id
                         AND    sub.data_cancellazione IS NULL
                         AND    sub.validita_fine IS NULL
                         AND    r.data_cancellazione IS NULL
                         AND    r.validita_fine IS NULL );
	  */
      -- 05.05.2017 Sofia HD-INC000001737424


      strmessaggio:='aggiornamento tabella di appoggio';
      UPDATE fase_bil_t_reimputazione
      SET   movgestnew_ts_id =movgesttsidret
      		,movgestnew_id =movgestidret
            ,data_modifica = clock_timestamp()
       		,fl_elab='S'
      WHERE  reimputazione_id = movgestrec.reimputazione_id;



    END LOOP;

    -- bonifica eventuali scarti
    select * into cleanrec from fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid ,enteproprietarioid );

	-- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo and cleanrec.codicerisultato =0 then
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che non hanno ancora attributo
	 strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
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
     and   mov.movgest_anno::integer>annoBilancio
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
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza con atto amministrativo antecedente.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    end if;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


    outfasebilelabretid:=p_fasebilelabid;
    if cleanrec.codicerisultato = -1 then
	    codicerisultato:=cleanrec.codicerisultato;
	    messaggiorisultato:=cleanrec.messaggiorisultato;
    else
	    codicerisultato:=0;
	    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    end if;



    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_sing
(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	motivo character varying,
    componenteDef character varying,  -- 05.06.2020 Sofia Jira siac-7593
	impostaprovvedimento character varying DEFAULT 'true'::character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying
)
RETURNS record
AS $body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    v_faseBilElabId    integer;
    v_bil_attr_id      integer;
    v_attr_code        varchar;
-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio     integer;
-- SIAC-6997 ---------------- FINE --------------------
    MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';
    CAP_UG_TIPO        CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO        CONSTANT varchar:='CAP-EG';
    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';
    v_boolean          char(1);
    v_attr_id          integer;
    v_bil_id           integer;
    faseRec record;
    faseElabRec record;

   -- 05.06.2020 Sofia Jira siac-7593
   paramComponent       varchar:=null;
   componenteFittizia   varchar:=null;
   componenteFresco     varchar:=null;
   componenteFPV        varchar:=null;
   motivoREIMP CONSTANT varchar:='REIMP';
   motivoREANNO CONSTANT varchar:='REANNO';

   componenteDefId integer:=null;
   componenteFrescoId integer:=null;
   componenteFPVId    integer:=null;
BEGIN
	v_faseBilElabId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    strMessaggioFinale:='Reimputazione Importi/ accertamenti a partire anno ='||annoBilancio::varchar||'.';

    select bil_id into v_bil_id from siac_t_bil where ente_proprietario_id = enteProprietarioId and bil_code = 'BIL_'||annoBilancio::varchar and data_cancellazione is null;
    if v_bil_id is  null then
        strMessaggio :='Bilancio non trovato anno ='||annoBilancio::varchar||'.';
    	raise exception 'Bilancio non trovato anno =%',annoBilancio::varchar;
    	return;
    end if;

    -- 05.06.2020 Sofia Jira siac-7593
    -- check delle componenti
    if p_movgest_tipo_code ='I'  then
      strMessaggio:='Lettura param componenti in tipo fase elaborazione '||APE_GEST_REIMP||'.';
      select tipo.fase_bil_elab_tipo_param into paramComponent
      from fase_bil_d_elaborazione_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null;
      raise notice 'paramComponent=%',paramComponent;
      if coalesce(paramComponent,'')!='' then
      	if coalesce(componenteDef,'')='S'  then
        	  componenteFittizia:=trim(split_part(paramComponent,'|',1));
              if coalesce(componenteFittizia,'')='' then
              	raise exception ' Componente fittizia richiesta non impostata a parametro.';
              end if;
              strMessaggio:='Lettura componente fittizia '||componenteFittizia||'.';
              select comp_tipo.elem_det_comp_tipo_id into componenteDefId
              from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
                   siac_d_bil_elem_Det_comp_tipo_stato stato
              where comp_tipo.ente_proprietario_id=enteProprietarioId
              and   comp_tipo.elem_det_comp_tipo_desc=componenteFittizia
              and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
              and   stato.elem_det_comp_tipo_stato_code!='A'
              and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
              and   tipo_imp.elem_Det_comp_tipo_imp_desc in ('Si','Auto') -- 21.07.2020 Sofia aggiunto Auto dopo conf. con Gambino P.
              and   comp_tipo.data_cancellazione is null
              and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
              and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                    date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
              raise notice 'componenteDefId=%',componenteDefId;
              if componenteDefId is  null then
                  raise exception ' Non esistente o non valida o impegnabile.';
              end if;
        else
              componenteFresco=trim(split_part(paramComponent,'|',2));
              if motivo=motivoREIMP then
              	componenteFPV=trim(split_part(paramComponent,'|',3));
              else
                componenteFPV=trim(split_part(paramComponent,'|',4));
              end if;
              if coalesce(componenteFresco,'')=''  or coalesce(componenteFPV,'')='' then
              	raise exception ' Componente Fresco/FPV  non impostata a parametro.';
              end if;

              strMessaggio:='Lettura componente Fresco '||componenteFresco||'.';
              select comp_tipo.elem_det_comp_tipo_id into componenteFrescoId
              from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
                   siac_d_bil_elem_Det_comp_tipo_stato stato
              where comp_tipo.ente_proprietario_id=enteProprietarioId
              and   comp_tipo.elem_det_comp_tipo_desc=componenteFresco
              and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
              and   stato.elem_det_comp_tipo_stato_code!='A'
              and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
              and   tipo_imp.elem_Det_comp_tipo_imp_desc in ('Si','Auto') -- 21.07.2020 Sofia aggiunto Auto dopo conf. con Gambino P.
              and   comp_tipo.data_cancellazione is null
              and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
              and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                    date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
              raise notice 'componenteFrescoId=%',componenteFrescoId;
              if componenteFrescoId is  null then
                  raise exception ' Non esistente o non valida o impegnabile.';
              end if;

              strMessaggio:='Lettura componente FPV '||componenteFPV||'.';
              select comp_tipo.elem_det_comp_tipo_id into componenteFPVId
              from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
                   siac_d_bil_elem_Det_comp_tipo_stato stato
              where comp_tipo.ente_proprietario_id=enteProprietarioId
              and   comp_tipo.elem_det_comp_tipo_desc=componenteFPV
              and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
              and   stato.elem_det_comp_tipo_stato_code!='A'
              and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
              and   tipo_imp.elem_Det_comp_tipo_imp_desc in ('Si','Auto') -- 21.07.2020 Sofia aggiunto Auto dopo conf. con Gambino P.
              and   comp_tipo.data_cancellazione is null
              and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
              and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                    date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
              raise notice 'componenteFPVId=%',componenteFPVId;
              if componenteFPVId is  null then
                  raise exception ' Non esistente o non valida o impegnabile.';
              end if;

        end if;


      else
    	raise exception ' Parametri non ricavati.';
    	return;
      end if;

    end if;
    -- 05.06.2020 Sofia Jira siac-7593 - fine

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
        strMessaggio :=' Esistenza elaborazione reimputazione in corso.';
    	raise exception ' Esistenza elaborazione reimputazione in corso.';
    	return;
    end if;

    -- 05.06.2020 Sofia Jira siac-7593

    strMessaggio:='Inserimento fase elaborazione [fnc_fasi_bil_gest_reimputa].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE IN CORSO. (TEST SERGIO)',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, p_dataElaborazione, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteproprietarioid
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into v_faseBilElabId;

     if v_faseBilElabId is null then
        strMessaggio  :=' Inserimento elaborazione per tipo APE_GEST_REIMP non effettuato.';
     	raise exception ' Inserimento elaborazione per tipo APE_GEST_REIMP non effettuato.';
     	return;
     end if;

/* -- SIAC-6997 ---------------- INIZIO --------------------
   -- tolto blocco elaborazione su controllo reimputazione gia eseguita in precedenza

A)
Il sistema verifica che l'elaborazione non sia gia stata effettuata:
SE per l'anno di bilancio in elaborazione il flagReimputaSpese e a TRUE l'elaborazione viene interrotta con l'errore
- quindi se su siac_t_bil per annoBilancio=2017
               siac_r_bil_attr per attr_code in flagReimputaSpese,flagReimputaEntrate il valore e impostato a S, se si blocchi elaborazione, se no procedi

Verificare che non ci siano elaborazioni in corso per APE_GEST_REIMP in fase_bil_t_elaborazione ( come fanno le altre function )
Inserire nella fase_bil_t_elaborazione il fase_elab_id per  APE_GEST_REIMP


    if p_movgest_tipo_code = 'I' then
        v_attr_code := 'flagReimputaSpese';
        select attr_id into v_attr_id  from siac.siac_t_attr where ente_proprietario_id = enteProprietarioId and   data_cancellazione is null and      attr_code = 'flagReimputaSpese';
    else
        v_attr_code := 'flagReimputaEntrate';
        select attr_id into v_attr_id  from siac_t_attr where ente_proprietario_id = enteProprietarioId and   data_cancellazione is null and      attr_code = 'flagReimputaEntrate';
    end if;

    select
    	siac_r_bil_attr.bil_attr_id,
    	siac_r_bil_attr.boolean
    into v_bil_attr_id,v_boolean
    from
    	siac_t_bil,siac_r_bil_attr,siac_t_attr
    where
    siac_t_bil.bil_id = siac_r_bil_attr.bil_id
    and siac_r_bil_attr.attr_id =  siac_t_attr.attr_id
    and siac_r_bil_attr.data_cancellazione is null
    and siac_t_attr.attr_code = v_attr_code
    and siac_t_bil.bil_code = 'BIL_'||annoBilancio::varchar
    --and siac_r_bil_attr.boolean != 'S'
    and siac_t_bil.ente_proprietario_id = enteProprietarioId;

    raise notice ' v_bil_attr_id %',v_bil_attr_id;

    if v_bil_attr_id is  null then
        insert into  siac_r_bil_attr (bil_id ,attr_id ,tabella_id ,boolean,percentuale,testo ,numerico ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione
        )
        VALUES( v_bil_id,v_attr_id,null,'N',null,null,null,now(),null,enteProprietarioId,null,loginOperazione)
        returning bil_attr_id into v_bil_attr_id; -- 26.01.2016 Sofia
    else
		if  v_boolean = 'S' then
            strMessaggio:=' Elaborazione terminata reimputazione gia eseguita in precedenza v_bil_attr_id-->'||v_bil_attr_id::varchar||'.';
            --raise notice ' Elaborazione terminata reimputazione gia eseguita in precedenza.';
			raise exception ' Elaborazione terminata reimputazione gia eseguita in precedenza.';
			return;
        end if;
    end if;

*/ -- SIAC-6997 --------------- FINE ------------------------

	select * into faseRec
    from fnc_fasi_bil_gest_reimputa_popola
    	 (
    	  v_faseBilElabId            ,
    	  enteProprietarioId     	,
          annoBilancio           	,
          loginOperazione        	,
          p_dataElaborazione       	,
          p_movgest_tipo_code        ,
-- SIAC-6997 ---------------- INIZIO --------------------
         motivo,
-- SIAC-6997 --------------- FINE ------------------------
		  -- 05.06.2020 Sofia Jira SIAC-7593
          ( case when p_movgest_tipo_code='I' then componenteDefId else null end),
          ( case when p_movgest_tipo_code='I' then componenteFrescoId else null end),
          ( case when p_movgest_tipo_code='I' then componenteFPVId else null end)
          -- 05.06.2020 Sofia Jira SIAC-7593
          );
    if faseRec.codiceRisultato=-1  then
     strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
     raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
     return;
    end if;

	select * into faseRec
    from fnc_fasi_bil_gest_reimputa_elabora
    	 (
    	  v_faseBilElabId,
    	  enteProprietarioId,
		  annoBilancio,
          impostaProvvedimento::boolean, -- 07.02.2018 Sofia siac-5638
		  loginOperazione,
		  p_dataElaborazione,
		  p_movgest_tipo_code
-- SIAC-6997 ---------------- INIZIO --------------------
          ,motivo
-- SIAC-6997 --------------- FINE ------------------------
          );
    if faseRec.codiceRisultato=-1  then
     strMessaggio:='Lancio elaborazione.'||faseRec.messaggioRisultato;
     raise exception ' Errore Lancio elaborazione % .',faseRec.messaggioRisultato;
     return;
    end if;

-- SIAC-6997 ---------------- INIZIO --------------------
-- tolto blocco elaborazione su controllo reimputazione gia eseguita in precedenza

--    strMessaggio:='Aggiornamento attributo reimputazione avvenuta con successo poi chiusura.';
--    update  siac_r_bil_attr set BOOLEAN='S',login_operazione = loginoperazione , data_modifica = now()
--    where   bil_attr_id = v_bil_attr_id;

    strMessaggio:='Aggiornamento attributo reimputazione avvenuta con successo poi chiusura.';

    v_annobilancio := annoBilancio;
    if motivo = 'REIMP' then
       v_annobilancio := annoBilancio - 1;
    end if;

update siac_t_modifica set elab_ror_reanno = TRUE
where mod_id in (
    select  modifica.mod_id
      from  siac_t_modifica             modifica,
            siac_d_modifica_tipo        modificaTipo,
			siac_t_bil                  bil,
			siac_t_bil_elem             bilel,
			siac_r_movgest_bil_elem     rbilel,
			siac_t_movgest              movgest,
			siac_t_movgest_ts_det       detts,
			siac_t_movgest_ts_det_mod   dettsmod,
			siac_r_modifica_stato       rmodstato,
			siac_d_modifica_stato       modstato,
			siac_d_movgest_ts_det_tipo  tipodet,
			siac_t_movgest_ts           tsmov,
			siac_d_movgest_tipo         tipomov,
			siac_d_movgest_ts_tipo      tipots,
			siac_t_movgest_ts_det       dettsIniz,
			siac_d_movgest_ts_det_tipo  tipodetIniz,
			siac_t_periodo              per,
			siac_d_bil_elem_tipo        dbileltip,
            siac_r_movgest_ts_stato     rstato
	 where  bil.ente_proprietario_id             = enteProprietarioId
	   and  bilel.elem_tipo_id                   = dbileltip.elem_tipo_id
	   and  bilel.elem_id                        = rbilel.elem_id
	   and  rbilel.movgest_id                    = movgest.movgest_id
	   and  per.periodo_id                       = bil.periodo_id
       and  per.anno::integer                    = v_annobilancio
       and  modifica.ente_proprietario_id        = bil.ente_proprietario_id
	   and  rmodstato.mod_id                     = modifica.mod_id
	   and  dettsmod.mod_stato_r_id              = rmodstato.mod_stato_r_id
	   and  modstato.mod_stato_id                = rmodstato.mod_stato_id
	   and  modstato.mod_stato_code              = 'V'
   	   and  modifica.mod_tipo_id                 = modificaTipo.mod_tipo_id
       and  modifica.elab_ror_reanno             = FALSE
       and  modificaTipo.mod_tipo_code           = motivo
       and  dettsmod.movgest_ts_det_importo      < 0
	   and  tipodet.movgest_ts_det_tipo_id       = dettsmod.movgest_ts_det_tipo_id
	   and  detts.movgest_ts_det_id              = dettsmod.movgest_ts_det_id
	   and  tsmov.movgest_ts_id                  = detts.movgest_ts_id
	   and  dettsIniz.movgest_ts_id              = tsmov.movgest_ts_id
	   and  tipodetIniz.movgest_ts_det_tipo_id   = dettsIniz.movgest_ts_det_tipo_id
	   and  tipodetIniz.movgest_ts_det_tipo_code = p_movgest_tipo_code
	   and  tipots.movgest_ts_tipo_id            = tsmov.movgest_ts_tipo_id
	   and  movgest.movgest_id                   = tsmov.movgest_id
	   and  movgest.bil_id                       = bil.bil_id
	   and  tipomov.movgest_tipo_id              = movgest.movgest_tipo_id
	   and  tipomov.movgest_tipo_code            = p_movgest_tipo_code
	   and  dettsmod.mtdm_reimputazione_anno     is not null
	   and  dettsmod.mtdm_reimputazione_flag     is true
       and  rstato.movgest_ts_id                 = tsmov.movgest_ts_id
	   and  bilel.validita_fine                  is null
	   and  rbilel.validita_fine                 is null
	   and  rmodstato.validita_fine              is null
	   and  tsmov.validita_fine                  is null
	   and  dettsIniz.validita_fine              is null
	   and  bil.validita_fine                    is null
	   and  per.validita_fine                    is null
	   and  modifica.validita_fine               is null
	   and  bilel.data_cancellazione             is null
	   and  rbilel.data_cancellazione            is null
	   and  rmodstato.data_cancellazione         is null
	   and  tsmov.data_cancellazione             is null
	   and  dettsIniz.data_cancellazione         is null
	   and  bil.data_cancellazione               is null
	   and  per.data_cancellazione               is null
	   and  modifica.data_cancellazione          is null
       and  rstato.data_cancellazione            is null
       and  rstato.validita_fine                 is null);

-- SIAC-6997 ---------------- FINE --------------------

    strMessaggio:='Aggiornamento stato fase bilancio OK per chiusura v_bil_attr_id-->'||v_bil_attr_id::varchar||'.';

    update fase_bil_t_elaborazione fase
    set fase_bil_elab_esito='OK',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_REIMP||' CHIUSURA.'
    where fase.fase_bil_elab_id=v_faseBilElabId;

    outfaseBilElabRetId:=v_faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	impostaprovvedimento character varying DEFAULT 'true'::character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying)
RETURNS record AS
$body$
DECLARE

	strMessaggio       VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    faseRec             record;
    v_motivo           VARCHAR(1500):='';

	-- 03.06.2020 Sofia Jira siac-7593
    componenteDef     varchar(50):=null;

    componenteFresco  constant varchar:='Fresco';
    componenteFPV     constant varchar:='FPV';

    sottoTipoDesc        constant varchar:='Applicato';

    faseCodeREIMP     constant varchar:='ROR effettivo';
    faseCodeREANNO    constant varchar:='Gestione';

    motivoCodeREIMP   constant varchar:='REIMP';
    motivoCodeREANNO   constant varchar:='REANNO';

    componenteDefId   integer:=null;
    componenteFrescoId  integer:=null;
    componenteFPVId     integer:=null;
    countComp  integer:=0;
BEGIN

    outfasebilelabretid:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    -- 03.06.2020 Sofia Jira siac-7593
	-- aggiungere estrazione della componente fittizia
    -- v_motivo:=TRIM(SUBSTR(p_movgest_tipo_code,3,6));
    v_motivo:=trim(upper(split_part(p_movgest_tipo_code,'|',2)));
    componenteDef:=trim(split_part(p_movgest_tipo_code,'|',3));
	raise notice 'v_motivo=%',v_motivo;
    raise notice 'componenteDef=%',componenteDef;

/*
	-- -- 03.06.2020 Sofia Jira siac-7593
	-- test sulle componenti
    if SUBSTR(p_movgest_tipo_code,1,1) = 'I' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
      strMessaggioFinale:='Reimputazione Principale anno = '||annoBilancio::varchar||'.'
         ||' Verifica esistenza componente fittizia '||componentedef||'.';
      -- fittizia
      if coalesce(componenteDef,'')!='' then
      	select comp_tipo.elem_det_comp_tipo_id into componenteDefId
        from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato
        where comp_tipo.ente_proprietario_id=enteProprietarioId
        and   comp_tipo.elem_det_comp_tipo_desc=componenteDef
        and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
        and   stato.elem_det_comp_tipo_stato_code!='A'
        and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
        and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
        and   comp_tipo.data_cancellazione is null
        and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
        and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
              date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
        raise notice 'componenteDefId=%',componenteDefId;
        if componenteDefId is  null then
      --  	strMessaggio:=' Non esistente o non valida.';
            raise exception ' Non esistente o non valida o impegnabile.';
        end if;
      end if;

       if coalesce(componenteDef,'')='' then
        strMessaggioFinale:='Reimputazione Principale anno = '||annoBilancio::varchar||'.'
         ||' Verifica esistenza componente '||componenteFresco||'.';
      	select comp_tipo.elem_det_comp_tipo_id into componenteFrescoId
        from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato,
             siac_d_bil_elem_det_comp_macro_tipo macro
        where comp_tipo.ente_proprietario_id=enteProprietarioId
        and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
        and   macro.elem_det_comp_macro_tipo_desc=componenteFresco
        and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
        and   stato.elem_det_comp_tipo_stato_code!='A'
        and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
        and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
        and   comp_tipo.data_cancellazione is null
        and   macro.data_cancellazione is null
        and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
        and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
              date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
		raise notice 'componenteFrescoId=%',componenteFrescoId;
        if componenteFrescoId is  null then
      --  	strMessaggio:=' Non esistente o non valida.';
            raise exception ' Non esistente o non valida o impegnabile.';
        end if;

        if componenteFrescoId is not null then
            countComp:=null;
            select 1 into countComp
            from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato,
             siac_d_bil_elem_det_comp_macro_tipo macro
            where comp_tipo.ente_proprietario_id=enteProprietarioId
            and   comp_tipo.elem_det_comp_tipo_id!=componenteFrescoId
            and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
            and   macro.elem_det_comp_macro_tipo_desc=componenteFresco
            and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
            and   stato.elem_det_comp_tipo_stato_code!='A'
            and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
            and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
            and   comp_tipo.data_cancellazione is null
            and   macro.data_cancellazione is null
            and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
            and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                  date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
       		raise notice 'countComp=%',countComp;

            if countComp is not null then
               --  	strMessaggio:=' Esistente non unica.';
               raise exception ' Esistente non unica.';
          --   return;
            end if;
        end if;
  		strMessaggioFinale:='Reimputazione Principale anno = '||annoBilancio::varchar||'.'
         ||' Verifica esistenza componente '||componenteFPV||'.';
      	select comp_tipo.elem_det_comp_tipo_id into componenteFPVId
        from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato,
             siac_d_bil_elem_det_comp_macro_tipo macro,
             siac_d_bil_elem_Det_comp_tipo_fase fase,
             siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo
        where comp_tipo.ente_proprietario_id=enteProprietarioId
        and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
        and   macro.elem_det_comp_macro_tipo_desc=componenteFPV
        and   fase.elem_det_comp_tipo_fase_id=comp_tipo.elem_det_comp_tipo_fase_id
        and   fase.elem_det_comp_tipo_fase_desc=
              ( case when v_motivo=motivoCodeREANNO then fasecodereanno
                else fasecodereimp end )
        and   sotto_tipo.elem_det_comp_sotto_tipo_id=comp_tipo.elem_det_comp_sotto_tipo_id
        and   sotto_tipo.elem_det_comp_sotto_tipo_desc=sottoTipoDesc
        and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
        and   stato.elem_det_comp_tipo_stato_code!='A'
        and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
        and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
        and   comp_tipo.data_cancellazione is null
        and   macro.data_cancellazione is null
        and   fase.data_cancellazione is null
        and   sotto_tipo.data_cancellazione is null
        and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
        and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
              date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
		raise notice 'componenteFPVId=%',componenteFPVId;
        if componenteFPVId is  null then
      --  	strMessaggio:=' Non esistente o non valida.';
            raise exception ' Non esistente o non valida o impegnabile.';
        end if;

         if componenteFPVId is not null then
            countComp:=null;
            select 1 into countComp
            from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
            	 siac_d_bil_elem_Det_comp_tipo_stato stato,
            	 siac_d_bil_elem_det_comp_macro_tipo macro,
                 siac_d_bil_elem_Det_comp_tipo_fase fase,
                 siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo
            where comp_tipo.ente_proprietario_id=enteProprietarioId
            and   comp_tipo.elem_det_comp_tipo_id!=componenteFPVId
            and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
            and   macro.elem_det_comp_macro_tipo_desc=componenteFPV
            and   fase.elem_det_comp_tipo_fase_id=comp_tipo.elem_det_comp_tipo_fase_id
     		and   fase.elem_det_comp_tipo_fase_desc=
            	  ( case when v_motivo=motivoCodeREANNO then fasecodereanno
            	    else fasecodereimp end )
            and   sotto_tipo.elem_det_comp_sotto_tipo_id=comp_tipo.elem_det_comp_sotto_tipo_id
            and   sotto_tipo.elem_det_comp_sotto_tipo_desc=sottoTipoDesc
            and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
            and   stato.elem_det_comp_tipo_stato_code!='A'
            and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
            and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
            and   comp_tipo.data_cancellazione is null
            and   macro.data_cancellazione is null
            and   fase.data_cancellazione is null
            and   sotto_tipo.data_cancellazione is null
            and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
            and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                  date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
       		raise notice 'countComp=%',countComp;

            if countComp is not null then
               --  	strMessaggio:=' Esistente non unica.';
               raise exception ' Esistente non unica.';
          --   return;
            end if;
        end if;
      end if;
    end if;

*/


    if SUBSTR(p_movgest_tipo_code,1,1) = 'I' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
       strMessaggioFinale:='1 - Reimputazione Principale (Impegni) a partire anno = '||annoBilancio::varchar||'.';

	   select * into faseRec
         from fnc_fasi_bil_gest_reimputa_sing
    	     (
               enteProprietarioId,
               annoBilancio,
               loginOperazione,
               p_dataElaborazione,
               'I',
               v_motivo,
               componenteDef,  -- 05.06.2020 Sofia Jira siac-7593
               impostaProvvedimento

              );
       if faseRec.codiceRisultato=-1  then
      --    strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
          raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
  --        return;
       end if;
       outfasebilelabretid:=faseRec.outfasebilelabretid;
    end if;



    if SUBSTR(p_movgest_tipo_code,1,1) = 'A' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
       strMessaggioFinale:='2 - Reimputazione Principale Accertamenti a partire anno = '||annoBilancio::varchar||'.';

  	   select * into faseRec
         from fnc_fasi_bil_gest_reimputa_sing
    	     (
              enteProprietarioId,
              annoBilancio,
              loginOperazione,
              p_dataElaborazione,
              'A',
              v_motivo,
              null,  -- 05.06.2020 Sofia Jira siac-7593
              impostaProvvedimento
              );
       if faseRec.codiceRisultato=-1  then
         -- strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
          raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
         -- return;
       end if;
       if SUBSTR(p_movgest_tipo_code,1,1) = 'A' then
          outfasebilelabretid:=faseRec.outfasebilelabretid;
       end if;
	end if;


    if SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
       strMessaggioFinale:='3 - Reimputazione Principale Vincoli a partire anno = '||annoBilancio::varchar||'.';

       select * into faseRec
         from fnc_fasi_bil_gest_reimputa_vincoli
         	 (
              enteProprietarioId,
              annoBilancio,
              loginOperazione,
              p_dataElaborazione
              );
        if faseRec.codiceRisultato=-1  then
      --     strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
           raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
     --      return;
        end if;
	end if;

    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--SIAC-7593 fine









