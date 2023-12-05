/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
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
		/* SIAC-8422 05/11/2021
           Gli importi totali dei residui devono essere messi a 0 in quanto
           non c'e' il relativo dettaglio.                                   
               case when entrate.attoamm_id_ent is NULL then
                    LPAD('0',17,'0') 
                  else trim(replace(to_char(ABS(entrate.variazione_residuo_ent) ,
          				'000000000000000.00'),'.','')) end || */
       /* SIAC-8817 04/11/2022    
           Si deve visualizzare di nuovo l'importo totale dei residui.      
                LPAD('0',17,'0') || */
                case when entrate.attoamm_id_ent is NULL then
                    LPAD('0',17,'0') 
                  else trim(replace(to_char(ABS(entrate.variazione_residuo_ent) ,
          				'000000000000000.00'),'.','')) end ||               	
                    --SENTRES Segno entrate residuo 
        /* SIAC-8422 05/11/2021 
        	Poiche' metto l'importo dei residui a 0, metto il segno +
               case when entrate.attoamm_id_ent is NULL then ' '                     
                else case when entrate.variazione_residuo_ent >=0 then '+'
                    else '-' end end || */       
        /* SIAC-8817 04/11/2022    
           Si deve visualizzare di nuovo l'impoero totale dei residui.             
                   '+' || */
                case when entrate.attoamm_id_ent is NULL then ' '                     
                else case when entrate.variazione_residuo_ent >=0 then '+'
                    else '-' end end ||   
                    --IUSCRES Importo spese residuo
		/* SIAC-8422 05/11/2021
           Gli importi totali dei residui devono essere messi a 0 in quanto
           non c'e' il relativo dettaglio.                                        
                case when spese.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0') 
                else trim(replace(to_char(ABS(spese.variazione_residuo_spese),
          				'000000000000000.00'),'.','')) end || */
		/* SIAC-8817 04/11/2022    
           Si deve visualizzare di nuovo l'impoero totale dei residui.                    
                    LPAD('0',17,'0') || */
                case when spese.attoamm_id_spese IS NULL then
                    LPAD('0',17,'0') 
                else trim(replace(to_char(ABS(spese.variazione_residuo_spese),
          				'000000000000000.00'),'.','')) end || 
                    --SUSCRES Segno spese residuo 
 		/* SIAC-8422 05/11/2021 
        	Poiche' metto l'importo dei residui a 0, metto il segno +                    
                case when spese.attoamm_id_spese IS NULL then ' '                         
                else case when spese.variazione_residuo_spese >=0 then '+'
                    else '-' end end ||  */
        /* SIAC-8817 04/11/2022    
           Si deve visualizzare di nuovo l'importo totale dei residui.             
                    '+' ||   */
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_tracciato_t2sb20s (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar, p_organo_provv varchar, p_code_report varchar, p_codice_ente varchar)
  OWNER TO siac;