/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR253_check_parameters" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar
)
RETURNS TABLE (
  display_error varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
x_array VARCHAR [];
intApp integer;
strApp varchar;
contaParVarBil integer;

BEGIN

/* 11/06/2021 SIAC-7790.
	Questa Procedura nasce per la verifica dei parametri per il report
    BILR253
*/


contaParVarBil:=0;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

if p_numero_delibera IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_delibera IS NOT  NULL AND p_anno_delibera <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_delibera IS NOT  NULL AND p_tipo_delibera <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione''';
    return next;
    return;        
end if;
 
if contaParVarBil = 3 and (p_ele_variazioni IS NOT NULL 
	AND p_ele_variazioni <> '') then
	display_error='Specificare uno solo tra i parametri ''Elenco numeri Variazione'' e ''Provvedimento di variazione''';
    return next;
    return;        
end if;    
    
display_error='';
return next;
return;   
             
raise notice 'fine OK';
exception
	when others  THEN
        RTN_MESSAGGIO:='Errore controllo parametri.';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;                 
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;