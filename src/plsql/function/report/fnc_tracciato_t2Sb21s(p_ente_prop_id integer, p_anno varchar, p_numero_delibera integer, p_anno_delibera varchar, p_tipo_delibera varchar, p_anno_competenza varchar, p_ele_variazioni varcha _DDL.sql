/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
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
/*  SIAC-8439 04/11/2021.
	Per risolvere definitivamente il problema della valorizzazione del campo
    NCAP nel caso dei capitoli senza codifica di bilancio, il controllo sul
    tipo di capitolo e' stato spostato nella query e si imposta il campo codifica_bil
    con il valore corretto.
    Non e' quindi piu' necessario raggruppare per il tipo capitolo e si evita
    di duplicare i record a parita' di codifica di bilancio.
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else '' end codifica_bil,     */       
                  
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else case when tipo_capitolo in ('FCI') THEN '8888888'
            	 	else '9999999' end
            end codifica_bil, 
      --SIAC-8367 04/10/2021.
      --Tolta l'estrazione del tipo capitolo ed il relativo
      -- raggruppamento perche' venivano duplicati i record a parita' 
      --di codifica di bilancio.            
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
/*  SIAC-8439 04/11/2021.
	Per risolvere definitivamente il problema della valorizzazione del campo
    NCAP nel caso dei capitoli senza codifica di bilancio, il controllo sul
    tipo di capitolo e' stato spostato nella query e si imposta il campo codifica_bil
    con il valore corretto.
    Non e' quindi piu' necessario raggruppare per il tipo capitolo e si evita
    di duplicare i record a parita' di codifica di bilancio.
				COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil, */   
                             
                case when COALESCE(programma_code,'')||COALESCE(titusc_code,'') <> '' then
                	COALESCE(programma_code,'')||COALESCE(titusc_code,'') 
                 else '9999999' end codifica_bil,
      --SIAC-8367 04/10/2021.
      --Tolta l'estrazione del tipo capitolo ed il relativo
      -- raggruppamento perche' venivano duplicati i record a parita' 
      --di codifica di bilancio.                  
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
/*  SIAC-8217 31/05/2021.
	Se non esiste la codifica se il capitolo e' FCI di entrata deve essere 8888888, 
    altrimenti 9999999.
	Se in futuro ci sara' la deficienza di cassa per le spese dovra' 
    essere 8888888, ma al momento questa tipologia di capitolo non e' 
    gestita. */
          -- LPAD(query_tot.codifica_bil, 7, '0') ||
          
/* SIAC-8367 04/10/2021.
   Si deve tornare indietro sulla modifica fatta per la SIAC-8217
   perche' si duplicano i record a parita' di codifica di bilancio e
   quindi non si puo' raggruppare per tipo capitolo.
   Occerrera' capire come gestire il caso del capitolo di entrata FCI.
              */
              
/*  SIAC-8439 04/11/2021.
	Per risolvere definitivamente il problema della valorizzazione del campo
    NCAP nel caso dei capitoli senza codifica di bilancio, il controllo sul
    tipo di capitolo e' stato spostato nella query e il campo codifica_bil
    contiene gia' il valore corretto sia per le entrate che per le spese.
    Non e' quindi piu' necessario raggruppare per il tipo capitolo e si evita
    di duplicare i record a parita' di codifica di bilancio.
     
        case when query_tot.tipo_record = 'E' then --Entrata          	
          	case when query_tot.tipo_capitolo in ('FCI') THEN            	
            	case when query_tot.codifica_bil <> '' then
         			LPAD(query_tot.codifica_bil, 7, '0')
          		else '8888888' end 
           else case when query_tot.codifica_bil <>'' then
          			LPAD(query_tot.codifica_bil, 7, '0')
          		else '9999999' end 
       		end 
          else -- Spesa
            case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end */
            
    /*      case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end ||      */   
            
           LPAD(query_tot.codifica_bil, 7, '0')  || 
                           
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
       from query_tot
/* SIAC-8422 04/11/2021.
	Devono essere escluse le righe che hanno tutti gli importi di variazione di
    competenza e cassa tutti a 0 */       
       where query_tot.variazione_aumento_stanziato <> 0 OR
       		 query_tot.variazione_diminuzione_stanziato <> 0 OR
             query_tot.variazione_aumento_cassa <> 0		OR
             query_tot.variazione_diminuzione_cassa <> 0
 /* SIAC-8817 04/11/2022.
 	Devo estrarre anche i dati dei residui.
    Tutti i dati sono uguali tranne:
    - NRES che deve contenere anno bilancio - 1 invece che 0;
    - IPIUCPT che deve contenere l'importo di variazione residui positivo invece 
    	che quello di competenza;
    - IMENCPT che deve contenere l'importo di variazione residui negativo invece 
    	che quello di competenza.
*/                         
      UNION
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
           LPAD(query_tot.codifica_bil, 7, '0')  ||                            
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo 
/*  Il campo NRES per i residui deve essere anno di bilancio - 1 */ 
          (p_anno::integer - 1)::varchar ||
          		--IPIUCPT Importo Variazione PIU' Residuo
          trim(replace(to_char(query_tot.variazione_aumento_residuo ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENCPT Importo Variazione MENO Residuo
          trim(replace(to_char(query_tot.variazione_diminuzione_residuo ,
          		'000000000000000.00'),'.','')) ||
           		--IPIUCAS Importo Variazione PIU' Cassa. E' sempre 0 per i residui
          LPAD('0', 17,'0') ||          
          		--IMENCAS Importo Variazione MENO Cassa. E' sempre 0 per i residui
          LPAD('0', 17,'0') ||
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
       from query_tot
       where query_tot.variazione_aumento_residuo <> 0 OR
       		 query_tot.variazione_diminuzione_residuo <> 0;
    
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
             

/*  SIAC-8439 04/11/2021.
	Per risolvere definitivamente il problema della valorizzazione del campo
    NCAP nel caso dei capitoli senza codifica di bilancio, il controllo sul
    tipo di capitolo e' stato spostato nella query e si imposta il campo codifica_bil
    con il valore corretto.
    Non e' quindi piu' necessario raggruppare per il tipo capitolo e si evita
    di duplicare i record a parita' di codifica di bilancio.
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else '' end codifica_bil,     */                         
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else case when tipo_capitolo in ('FCI') THEN '8888888'
            	 	else '9999999' end
            end codifica_bil,              
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
/*  SIAC-8439 04/11/2021.
	Per risolvere definitivamente il problema della valorizzazione del campo
    NCAP nel caso dei capitoli senza codifica di bilancio, il controllo sul
    tipo di capitolo e' stato spostato nella query e si imposta il campo codifica_bil
    con il valore corretto.
    Non e' quindi piu' necessario raggruppare per il tipo capitolo e si evita
    di duplicare i record a parita' di codifica di bilancio.
				COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil, */   
                             
                case when COALESCE(programma_code,'')||COALESCE(titusc_code,'') <> '' then
                	COALESCE(programma_code,'')||COALESCE(titusc_code,'') 
                 else '9999999' end codifica_bil,                
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
    /*  SIAC-8217 31/05/2021.
	Se non esiste la codifica se il capitolo e' FCI di entrata deve essere 8888888, 
    altrimenti 9999999.
	Se in futuro ci sara' la deficienza di cassa per le spese dovra' 
    essere 8888888, ma al momento questa tipologia di capitolo non e' 
    gestita. */
          -- LPAD(query_tot.codifica_bil, 7, '0') ||
          
/* SIAC-8367 04/10/2021.
   Si deve tornare indietro sulla modifica fatta per la SIAC-8217
   perche' si duplicano i record a parita' di codifica di bilancio e
   quindi non si puo' raggruppare per tipo capitolo.
   Occerrera' capire come gestire il caso del capitolo di entrata FCI.          
          case when query_tot.tipo_record = 'E' then --Entrata          	
          	case when query_tot.tipo_capitolo in ('FCI') THEN            	
            	case when query_tot.codifica_bil <> '' then
         			LPAD(query_tot.codifica_bil, 7, '0')
          		else '8888888' end 
           else case when query_tot.codifica_bil <>'' then
          			LPAD(query_tot.codifica_bil, 7, '0')
          		else '9999999' end 
       		end 
          else -- Spesa
            case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end 
            end || */
            
/*  SIAC-8439 04/11/2021.
	Per risolvere definitivamente il problema della valorizzazione del campo
    NCAP nel caso dei capitoli senza codifica di bilancio, il controllo sul
    tipo di capitolo e' stato spostato nella query e il campo codifica_bil
    contiene gia' il valore corretto sia per le entrate che per le spese.
    Non e' quindi piu' necessario raggruppare per il tipo capitolo e si evita
    di duplicare i record a parita' di codifica di bilancio.
            
          case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end ||  */

           LPAD(query_tot.codifica_bil, 7, '0')  ||                                   
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
       from query_tot
/* SIAC-8422 04/11/2021.
	Devono essere escluse le righe che hanno tutti gli importi di variazione di
    competenza a 0 */ 
    	where query_tot.variazione_aumento_stanziato <> 0 OR  
        	  query_tot.variazione_diminuzione_stanziato <> 0;                   
                
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_tracciato_t2sb21s (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar, p_organo_provv varchar, p_code_report varchar, p_codice_ente varchar)
  OWNER TO siac;