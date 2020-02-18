/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR090_riepilogo_anticipo_miss_trasf" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cassaecon_id integer,
  p_data_da date,
  p_data_a date
)
RETURNS TABLE (
  nome_ente varchar,
  anno_ese_finanz integer,
  cod_settore varchar,
  cod_capitolo varchar,
  cod_articolo varchar,
  benef_matricola varchar,
  benef_cognome varchar,
  benef_nome varchar,
  num_sospeso integer,
  data_pagamento date,
  data_missione_dal date,
  data_missione_al date,
  importo numeric,
  importo_anticipo numeric,
  importo_recuperi numeric,
  flag_estero varchar,
  tipo_richiesta varchar,
  desc_richiesta varchar,
  num_movimento integer,
  num_impegno integer,
  anno_impegno integer
) AS
$body$
DECLARE
elencoAnticipi record;
dati_giustif record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

anno_eser_int INTEGER;



BEGIN

nome_ente='';
anno_ese_finanz=0;
cod_settore='';
cod_capitolo='';
cod_articolo='';
benef_matricola ='';
benef_cognome='';
benef_nome='';
num_sospeso=NULL;
data_pagamento=NULL;
data_missione_dal=NULL;
data_missione_al=NULL;
importo=0;
importo_anticipo=0;
importo_recuperi=0;
flag_estero='';
tipo_richiesta='';
desc_richiesta='';
num_movimento=0;
num_impegno=0;
anno_impegno=0;

RTN_MESSAGGIO:='Estrazione dei dati degli anticipi ''.';

raise notice 'Estrazione dei dati egli anticipi';
raise notice 'ora: % ',clock_timestamp()::varchar;

anno_eser_int=p_anno :: INTEGER;

 BEGIN
  SELECT  r_cassa_econ_attr.testo
      INTO cod_settore
      from siac_t_attr								t_attr,
    		siac_r_cassa_econ_attr					r_cassa_econ_attr                  
  where t_attr.attr_id=r_cassa_econ_attr.attr_id
   		 AND r_cassa_econ_attr.cassaecon_id=p_cassaecon_id
         AND t_attr.attr_code='intestazioneSettore'
         AND t_attr.ente_proprietario_id=p_ente_prop_id
       AND r_cassa_econ_attr.data_cancellazione is NULL
       AND t_attr.data_cancellazione is NULL;	
 IF NOT FOUND THEN
    /* se non esiste la direzione restituisco un codice fittizio */
  cod_settore='';
  raise notice 'Non esiste il settore per la cassa con ID %',  p_cassaecon_id;       
  END IF;
END;

for elencoAnticipi in
select ente_prop.ente_denominazione,
	richiesta_econ.ricecon_codice_beneficiario,
	richiesta_econ.ricecon_codice_fiscale,
    richiesta_econ.ricecon_cognome,
    richiesta_econ.ricecon_nome,
    richiesta_econ.ricecon_matricola,
    richiesta_econ.ricecon_importo,
    richiesta_econ.ricecon_desc, 
    richiesta_econ_sospesa.ricecons_numero num_sospeso,
    movimento.movt_pagamento_dettaglio,
    movimento.movt_data,
    movimento.gst_id,
    anno_eserc.anno,
    movimento.movt_numero, 
    t_movgest.movgest_anno anno_impegno,
    t_movgest.movgest_numero numero_impegno, 
    richiesta_econ_tipo.ricecon_tipo_code,
    t_trasf_miss.tramis_desc,
    t_trasf_miss.tramis_inizio,
    t_trasf_miss.tramis_fine,
    t_trasf_miss.tramis_flagestero,
    t_bil_elem.elem_code cod_capitolo,
    t_bil_elem.elem_code2 cod_articolo
from siac_t_ente_proprietario				ente_prop,
	siac_t_movimento						movimento,
	siac_r_richiesta_econ_stato				r_richiesta_stato,
 	siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
	siac_d_richiesta_econ_stato				richiesta_stato,
    siac_t_periodo 							anno_eserc,
    siac_t_bil 								bilancio,
    siac_d_cassa_econ_modpag_tipo   		mod_pag_tipo,
    siac_t_trasf_miss						t_trasf_miss,
    siac_r_richiesta_econ_movgest			r_rich_econ_movgest,
    siac_t_movgest							t_movgest,
    siac_t_movgest_ts						t_movgest_ts,
    siac_r_movgest_bil_elem					r_movgest_bil_elem,
    siac_t_bil_elem							t_bil_elem,    
	siac_t_richiesta_econ 					richiesta_econ
	 LEFT join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
            on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
            	AND richiesta_econ_sospesa.data_cancellazione IS NULL)       
WHERE  ente_prop.ente_proprietario_id=richiesta_econ.ente_proprietario_id
	AND movimento.ricecon_id=richiesta_econ.ricecon_id
    AND mod_pag_tipo.cassamodpag_tipo_id=movimento.cassamodpag_tipo_id
	AND richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
	AND r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id
    AND richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id
    AND richiesta_econ.bil_id=bilancio.bil_id
    AND bilancio.periodo_id=anno_eserc.periodo_id
    AND t_trasf_miss.ricecon_id = richiesta_econ.ricecon_id
    AND r_rich_econ_movgest.ricecon_id=richiesta_econ.ricecon_id
    AND t_movgest.movgest_id=t_movgest_ts.movgest_id
    AND t_movgest_ts.movgest_ts_id=r_rich_econ_movgest.movgest_ts_id
    AND r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
    AND r_movgest_bil_elem.elem_id=t_bil_elem.elem_id
    AND richiesta_econ.ente_proprietario_id=p_ente_prop_id
    AND richiesta_econ.cassaecon_id=p_cassaecon_id
    AND anno_eserc.anno=p_anno
    AND movimento.movt_data between p_data_da AND p_data_a
    AND richiesta_stato.ricecon_stato_code<>'AN' -- Annullati
    AND richiesta_econ_tipo.ricecon_tipo_code in ('ANTICIPO_SPESE_MISSIONE','ANTICIPO_TRASFERTA_DIPENDENTI')   
	AND ente_prop.data_cancellazione IS NULL
    AND movimento.data_cancellazione IS NULL
    AND r_richiesta_stato.data_cancellazione IS NULL
    AND richiesta_econ_tipo.data_cancellazione IS NULL
    AND richiesta_stato.data_cancellazione IS NULL
    AND anno_eserc.data_cancellazione IS NULL
    AND bilancio.data_cancellazione IS NULL
    AND mod_pag_tipo.data_cancellazione IS NULL
    AND t_trasf_miss.data_cancellazione IS NULL
    AND r_rich_econ_movgest.data_cancellazione IS NULL
    AND t_movgest.data_cancellazione IS NULL
    AND t_movgest_ts.data_cancellazione IS NULL
    AND r_movgest_bil_elem.data_cancellazione IS NULL
    AND t_bil_elem.data_cancellazione IS NULL
    AND richiesta_econ.data_cancellazione IS NULL
loop
      
nome_ente=COALESCE(elencoAnticipi.ente_denominazione,'');
anno_ese_finanz=elencoAnticipi.anno;
benef_matricola =COALESCE(elencoAnticipi.ricecon_matricola,'');
benef_cognome=COALESCE(elencoAnticipi.ricecon_cognome,'');
benef_nome=COALESCE(elencoAnticipi.ricecon_nome,'');
	/* 01/03/2016: ci sono casi in cui i campi benef_cognome e benef_nome
    	contengono sia il cognome che  il nome.
        In questo caso valorizzo solo il cognome.
        A volte invece benef_cognome contiene entrambi mentre benef_nome solo il nome */

if upper(benef_cognome)=upper(benef_nome) THEN
	benef_nome='';
elsif upper(substring(benef_cognome from char_length(benef_cognome)-(char_length(benef_nome)-1) 
	for char_length(benef_nome)))=upper(benef_nome) THEN
    	benef_nome='';
end if;

num_sospeso=elencoAnticipi.num_sospeso;
data_pagamento=elencoAnticipi.movt_data;
num_movimento=elencoAnticipi.movt_numero;
num_impegno=elencoAnticipi.numero_impegno;
anno_impegno=elencoAnticipi.anno_impegno;

if elencoAnticipi.gst_id is not NULL THEN                      
    SELECT rend_importo_restituito, rend_importo_integrato
      INTO dati_giustif
      FROM siac_t_giustificativo
      WHERE gst_id = elencoAnticipi.gst_id;
      IF NOT FOUND THEN
          RAISE EXCEPTION 'Non esiste il giustificativo %', elenco_movimenti.gst_id;
          return;
      ELSE
                      /* se esiste un importo restituito prendo questo con segno negativo */
      	if dati_giustif.rend_importo_restituito > 0 THEN                  
        	importo = -dati_giustif.rend_importo_restituito;
        elsif dati_giustif.rend_importo_integrato > 0 THEN
        	importo = dati_giustif.rend_importo_integrato;
        else 
        	importo=0;
        end if;
    END IF;   
else
	importo=COALESCE(elencoAnticipi.ricecon_importo,0);    
end if;
--importo=COALESCE(elencoAnticipi.ricecon_importo,0);

tipo_richiesta=elencoAnticipi.ricecon_tipo_code;
data_missione_dal=elencoAnticipi.tramis_inizio;
data_missione_al=elencoAnticipi.tramis_fine;
flag_estero=elencoAnticipi.tramis_flagestero;
desc_richiesta=COALESCE(elencoAnticipi.tramis_desc,'');     
  
cod_capitolo=elencoAnticipi.cod_capitolo;
cod_articolo=elencoAnticipi.cod_articolo;

return next;


nome_ente='';
anno_ese_finanz=0;
cod_capitolo='';
cod_articolo='';
benef_matricola ='';
benef_cognome='';
benef_nome='';
num_sospeso=NULL;
data_pagamento=NULL;
data_missione_dal=NULL;
data_missione_al=NULL;
importo=0;
importo_anticipo=0;
importo_recuperi=0;
flag_estero='';
tipo_richiesta='';
desc_richiesta='';
num_movimento=0;
num_impegno=0;
anno_impegno=0;

end loop;

raise notice 'fine estrazione dei dati';  
raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'nessun reversale trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;