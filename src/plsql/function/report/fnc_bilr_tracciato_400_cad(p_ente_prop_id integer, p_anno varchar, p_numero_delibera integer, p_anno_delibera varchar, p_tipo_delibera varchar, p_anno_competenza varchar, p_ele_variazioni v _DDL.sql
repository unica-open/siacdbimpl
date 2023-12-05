/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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