/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
/*  SIAC-8217 31/05/2021.
	Se non esiste la codifica riporto 9999999.
    Se in futuro ci sara' la deficienza di cassa per le spese dovra' 
    essere 8888888, ma al momento questa tipologia di capitolo non e' 
    gestita. */              
          --LPAD(spese.codifica_bil, 7, '0') ||
          case when spese.codifica_bil <>'' then
              LPAD(spese.codifica_bil, 7, '0')
            else '9999999' end ||
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo 
                --13/10/2020 SIAC-7828. Il tag NRES deve essere sempre '0000'
          --p_anno_competenza ||
         '0000' ||
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
      order by attoamm_id, codifica_bil) spese
     /* SIAC-8422 04/11/2021.
	Devono essere escluse le righe che hanno tutti gli importi di variazione di
    competenza tutti a 0 */
    	where spese.variazione_aumento_stanziato <> 0 OR
            spese.variazione_diminuzione_stanziato <> 0  ;
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