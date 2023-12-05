/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR109_estrai_titoli" (
  p_ente_prop_id integer
)
RETURNS TABLE (
  titolo_code varchar,
  titolo_desc varchar,
  titolo_composto varchar
) AS
$body$
DECLARE

classifBilRec record;

strTempCode varchar;
strTempDesc varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN

/*
	Funzione per estrarre i titoli configurati.
    I titoli 2 e 3 devono essere restituiti insieme per esigenze del report
    BILR109 (SIAC-6089).
*/


RTN_MESSAGGIO:='acquisizione dati ''.';  
 
raise notice 'acquisizione dati';
raise notice 'ora: % ',clock_timestamp()::varchar;
 
strTempCode:='';
strTempDesc:='';

for classifBilRec in
  SELECT distinct srtm.titolo, titusc.classif_desc
  FROM siac_d_class_fam titusc_fam, siac_t_class_fam_tree titusc_tree, 
       siac_r_class_fam_tree titusc_r_cft, siac_t_class titusc, 
       siac_d_class_tipo titusc_tipo, siac_rep_titolo_missione srtm
  WHERE titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id
    AND srtm.titolo = titusc.classif_code
    AND srtm.ente_proprietario_id = p_ente_prop_id
  ORDER BY srtm.titolo
loop
  if classifBilRec.titolo not in ('2','3') THEN
  	titolo_code := classifBilRec.titolo;
  	titolo_desc := classifBilRec.classif_desc;
    titolo_composto := titolo_code||' - '|| titolo_desc;
    return next;
  elsif classifBilRec.titolo = '2' THEN 
  	strTempCode:= classifBilRec.titolo;
    strTempDesc:= classifBilRec.classif_desc;
  else 
  	titolo_code := strTempCode ;
  	titolo_desc := strTempDesc || ' - '|| classifBilRec.classif_desc;
    titolo_composto := strTempCode|| ' - '|| strTempDesc ||
    	  ' - '|| classifBilRec.titolo||' - '|| classifBilRec.classif_desc;
    return next;
  end if;
  		 

	titolo_code:= '';
    titolo_desc:= '';
    titolo_composto:= '';

end loop;

raise notice 'fine preparazione dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;


raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
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