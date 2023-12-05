/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--SIAC-8854 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR265_stampa_mandati_reversali_vincoli" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_codice_vincolo varchar
)
RETURNS TABLE (
  vincolo_gen_code varchar,
  vincolo_gen_desc varchar,
  vincolo_code varchar,
  vincolo_desc varchar,
  elem_id integer,
  elem_code varchar,
  elem_code2 varchar,
  elem_desc varchar,
  tipo_capitolo varchar,
  ord_anno integer,
  ord_numero numeric,
  tipo_ordinativo varchar,
  stato_ord_code varchar,
  stato_ord_desc varchar,
  conto_tesoreria varchar,
  conto_tesoreria_pertinenza varchar,
  importo_ordinativo numeric
) AS
$body$
DECLARE
bilancio_id integer;
str_query varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN

/*
	29/08/2023.
  Funzione creata per la SIAC-8854 per il report BILR265.
  La funzione estrae mandati e reversali collegati a sottoconti vincolati.

*/

elemTipoCodeE:='CAP-EG';
elemTipoCodeS:='CAP-UG';

select bil.bil_id
	INTO bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id = per.periodo_id
and bil.ente_proprietario_id=p_ente_prop_id
and per.anno=p_anno
and bil.data_cancellazione IS NULL;

raise notice 'elem_id di % = %', p_anno, bilancio_id;


str_query:='select vinc_genere.vincolo_gen_code::varchar vincolo_gen_code, vinc_genere.vincolo_gen_desc::varchar vincolo_gen_desc, 
vinc.vincolo_code::varchar vincolo_code, vinc.vincolo_desc::varchar vincolo_desc,
cap.elem_id::integer elem_id,  cap.elem_code::varchar elem_code, cap.elem_code2::varchar elem_code2, 
cap.elem_desc::varchar elem_desc, 
case when tipo_cap.elem_tipo_code = '''||elemTipoCodeE ||'''
	then''Entrata''::varchar 
    else ''Spesa''::varchar end tipo_capitolo, 
ord.ord_anno::integer ord_anno, ord.ord_numero::numeric ord_numero, ord_tipo.ord_tipo_code::varchar tipo_ordinativo,
ord_stato.ord_stato_code::varchar stato_ord_code, ord_stato.ord_stato_desc::varchar stato_ord_desc, 
COALESCE(contotes.contotes_code,'''')::varchar conto_tesoreria, 
COALESCE(contites_pert.contotes_code,'''')::varchar conto_tesoreria_pertinenza,
ord_ts_det.ord_ts_det_importo::numeric importo_ordinativo 
from siac_t_bil_elem cap,
	siac_r_vincolo_bil_elem r_cap_vincolo,
    siac_t_vincolo vinc,
    siac_d_bil_elem_tipo tipo_cap,
    siac_r_vincolo_genere r_vinc_genere,
    siac_d_vincolo_genere vinc_genere,
    siac_r_ordinativo_bil_elem r_ord_cap,
    siac_t_ordinativo ord
    	left join siac_d_contotesoreria contotes
        	on contotes.contotes_id=ord.contotes_id and contotes.data_cancellazione IS NULL
        left join (select r_ord_conto_des_pert.ord_id, contotes_pert.contotes_id, 
        				contotes_pert.contotes_code, contotes_pert.contotes_desc
        			from siac_r_ordinativo_contotes_nodisp r_ord_conto_des_pert,
                    	siac_d_contotesoreria contotes_pert
                    where r_ord_conto_des_pert.contotes_id=contotes_pert.contotes_id
                    	and r_ord_conto_des_pert.data_cancellazione IS NULL) contites_pert
            on contites_pert.ord_id=ord.ord_id,
    siac_d_ordinativo_tipo ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
    siac_d_ordinativo_stato ord_stato,
    siac_t_ordinativo_ts ord_ts,
    siac_t_ordinativo_ts_det ord_ts_det,
    siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo
where cap.elem_id=   r_cap_vincolo.elem_id
    and r_cap_vincolo.vincolo_id=vinc.vincolo_id
    and tipo_cap.elem_tipo_id=cap.elem_tipo_id
    and r_vinc_genere.vincolo_id=vinc.vincolo_id
    and r_vinc_genere.vincolo_gen_id=vinc_genere.vincolo_gen_id
    and r_ord_cap.elem_id=cap.elem_id
    and r_ord_cap.ord_id=ord.ord_id
    and ord_tipo.ord_tipo_id=ord.ord_tipo_id
    and r_ord_stato.ord_id=ord.ord_id
    and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
    and ord_ts.ord_id=ord.ord_id
    and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
    and r_cap_vincolo.ente_proprietario_id='||p_ente_prop_id||'
    and cap.bil_id='||bilancio_id ||'
    and tipo_cap.elem_tipo_code in ('''||elemTipoCodeE||''', '''||elemTipoCodeS||''')
    and ord_stato.ord_stato_code <> ''A'' --escludo gli annullati
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code=''A'' --Importo Attuale';
    if trim(COALESCE(p_codice_vincolo,'')) <> '' then
    	str_query:=str_query||' 
        and upper(vinc.vincolo_code) like ''%'||upper(trim(p_codice_vincolo))||'%'' ';
    end if;
    
    str_query:=str_query||'
    and r_cap_vincolo.data_cancellazione IS NULL
    and r_vinc_genere.data_cancellazione IS NULL
    and r_ord_cap.data_cancellazione IS NULL
    and r_ord_stato.data_cancellazione IS NULL
    and r_ord_stato.validita_fine IS NULL
    and ord.data_cancellazione IS NULL
    and ord_ts.data_cancellazione IS NULL
    and ord_ts_det.data_cancellazione IS NULL
ORDER BY vincolo_code, tipo_capitolo, elem_code, elem_code2, ord_anno, ord_numero, stato_ord_code,
	    conto_tesoreria, conto_tesoreria_pertinenza';
        
raise notice 'Query: %', str_query;
        
return query execute str_query;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='altro errore generico';
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

ALTER FUNCTION siac."BILR265_stampa_mandati_reversali_vincoli" (p_ente_prop_id integer, p_anno varchar, p_codice_vincolo varchar)
  OWNER TO siac;
  
--SIAC-8854 - Maurizio - fine
  