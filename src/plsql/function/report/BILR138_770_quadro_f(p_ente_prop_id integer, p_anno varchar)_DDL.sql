/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR138_770_quadro_f" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  codice_fiscale_ente varchar,
  denominazione_ente varchar,
  indirizzo_ente varchar,
  cap_ente varchar,
  "città_ente" varchar,
  provincia_ente varchar,
  cognome_denominazione varchar,
  nome varchar,
  codice_fiscale_percipiente varchar,
  indirizzo_domicilio_fiscale varchar,
  cap_domicilio_spedizione varchar,
  comune_domicilio_fiscale varchar,
  provincia_domicilio_fiscale varchar,
  descrizione_onere varchar,
  ammontare_lordo_corrisposto numeric,
  altre_somme_no_ritenute numeric,
  imponibile numeric,
  imposta numeric,
  ritenute_operate numeric,
  detrazioni numeric,
  netto numeric,
  responsabile_amministrativo varchar,
  codice_tributo varchar
) AS
$body$
DECLARE

rec770_f      record;
DEF_NULL	  constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

v_soggetto_id    integer;
v_comune_id      integer;
v_zip_code       varchar;
v_toponimo       varchar;
v_numero_civico  varchar;
v_frazione       varchar;
v_interno        varchar;
v_via_tipo_id    integer;
v_via_tipo_desc  varchar;
v_indirizzo      varchar;
v_comune_desc    varchar;
v_provincia_desc varchar;
v_nazione_desc   varchar;

BEGIN

codice_fiscale_ente := '';
denominazione_ente := '';
indirizzo_ente := '';
CAP_ente := '';
città_ente := '';
provincia_ente := '';
cognome_denominazione := '';
nome := '';
codice_fiscale_percipiente := '';
indirizzo_domicilio_fiscale := '';
cap_domicilio_spedizione := '';
comune_domicilio_fiscale := '';
provincia_domicilio_fiscale := '';
descrizione_onere := '';
codice_tributo := '';
ammontare_lordo_corrisposto := 0;
altre_somme_no_ritenute := 0;
imponibile := 0;
imposta := 0;
ritenute_operate := 0;
detrazioni := 0;
netto := 0;
responsabile_amministrativo := '';
      
RTN_MESSAGGIO:='lettura dati Ente';  
raise notice '1: %', clock_timestamp()::varchar;  

SELECT upper(tep.ente_denominazione)
INTO   denominazione_ente
FROM   siac_t_ente_proprietario tep
WHERE  tep.ente_proprietario_id = p_ente_prop_id
AND    now() BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, now())
AND    tep.data_cancellazione IS NULL;

v_soggetto_id := null;

SELECT sep.soggetto_id
INTO   v_soggetto_id 
FROM   siac_r_soggetto_ente_proprietario sep
WHERE  sep.ente_proprietario_id = p_ente_prop_id
AND    now() BETWEEN sep.validita_inizio AND COALESCE(sep.validita_fine, now())
AND    sep.data_cancellazione IS NULL;

v_comune_id := null;
v_zip_code := null;
v_toponimo := null;
v_numero_civico := null;
v_frazione := null;
v_interno := null;
v_via_tipo_id := null;   

SELECT tis.comune_id, tis.zip_code, 
       tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
       -- dit.indirizzo_tipo_code
INTO   v_comune_id, v_zip_code,
       v_toponimo, v_numero_civico, v_frazione, v_interno, v_via_tipo_id
FROM   siac.siac_t_indirizzo_soggetto tis
/*INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                    AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                    AND rist.data_cancellazione IS NULL
INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                          AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                          AND dit.data_cancellazione IS NULL*/
WHERE tis.soggetto_id = v_soggetto_id
AND   tis.principale = 'S'
AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
AND   tis.data_cancellazione IS NULL;

v_via_tipo_desc := null;
v_indirizzo := null;

BEGIN
      
  SELECT dvt.via_tipo_desc
  INTO STRICT v_via_tipo_desc
  FROM siac.siac_d_via_tipo dvt
  WHERE dvt.via_tipo_id = v_via_tipo_id
  AND now() BETWEEN dvt.validita_inizio AND COALESCE(dvt.validita_fine, now())
  AND dvt.data_cancellazione IS NULL;
      
EXCEPTION
      
  WHEN NO_DATA_FOUND THEN
      v_via_tipo_desc := null;
      
END;
      
IF v_via_tipo_desc IS NOT NULL THEN
   v_indirizzo := v_via_tipo_desc;
END IF;

IF v_toponimo IS NOT NULL THEN
   v_indirizzo := v_indirizzo||' '||v_toponimo;
END IF;

IF v_numero_civico IS NOT NULL THEN
   v_indirizzo := v_indirizzo||' '||v_numero_civico;
END IF;

IF v_frazione IS NOT NULL THEN
   v_indirizzo := v_indirizzo||', frazione '||v_frazione;
END IF;

IF v_interno IS NOT NULL THEN
   v_indirizzo := v_indirizzo||', interno '||v_interno;
END IF;

v_comune_desc := null;
v_provincia_desc := null;
v_nazione_desc := null;

BEGIN

  SELECT tc.comune_desc, tp.sigla_automobilistica, tn.nazione_desc
  INTO  STRICT v_comune_desc, v_provincia_desc, v_nazione_desc
  FROM siac.siac_t_comune tc
  LEFT JOIN siac.siac_r_comune_provincia rcp ON rcp.comune_id = tc.comune_id
                                             AND now() BETWEEN rcp.validita_inizio AND COALESCE(rcp.validita_fine, now())
                                             AND rcp.data_cancellazione IS NULL
  LEFT JOIN siac.siac_t_provincia tp ON tp.provincia_id = rcp.provincia_id
                                     AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
                                     AND tp.data_cancellazione IS NULL
  LEFT JOIN siac.siac_t_nazione tn ON tn.nazione_id = tc.nazione_id
                                   AND now() BETWEEN tn.validita_inizio AND COALESCE(tn.validita_fine, now())
                                   AND tn.data_cancellazione IS NULL
  WHERE tc.comune_id = v_comune_id
  AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
  AND tc.data_cancellazione IS NULL;

EXCEPTION
                
  WHEN NO_DATA_FOUND THEN
       null;
                
END;

indirizzo_ente := upper(v_indirizzo);
CAP_ente := upper(v_zip_code);
città_ente := upper(v_comune_desc);
provincia_ente := upper(v_provincia_desc);

raise notice '2: %', clock_timestamp()::varchar;  

RTN_MESSAGGIO:='lettura dati 770';  
raise notice '3: %', clock_timestamp()::varchar;  

FOR rec770_f IN
  SELECT
    a.codice_fiscale_ente,
    a.codice_fiscale_percipiente,
    upper(a.cognome_denominazione) cognome_denominazione,
    upper(a.nome) nome,
    upper(a.comune_domicilio_fiscale) comune_domicilio_fiscale,
    upper(a.provincia_domicilio_fiscale) provincia_domicilio_fiscale,
    upper(a.indirizzo_domicilio_fiscale) indirizzo_domicilio_fiscale,
    upper(a.cap_domicilio_spedizione) cap_domicilio_spedizione,
    SUM(coalesce(a.ammontare_lordo_corrisposto,0)) ammontare_lordo_corrisposto,
    SUM(coalesce(a.altre_somme_no_ritenute,0)) altre_somme_no_ritenute,
    SUM(coalesce(a.ritenute_operate,0)) ritenute_operate,
    a.codice_tributo
  FROM  tracciato_770_quadro_f_temp a
  WHERE a.ente_proprietario_id = p_ente_prop_id
  AND   a.anno_competenza = p_anno
  AND   a.elab_id_temp = (SELECT MAX(b.elab_id_temp)
                          FROM  tracciato_770_quadro_f_temp b
                          WHERE a.ente_proprietario_id = b.ente_proprietario_id
                          AND   a.anno_competenza = b.anno_competenza
                         )
  GROUP BY
    a.codice_fiscale_ente,
    a.codice_fiscale_percipiente,
    a.cognome_denominazione,
    a.nome,
    a.comune_domicilio_fiscale,
    a.provincia_domicilio_fiscale,
    a.indirizzo_domicilio_fiscale,
    a.cap_domicilio_spedizione,
    a.codice_tributo
  ORDER BY a.cognome_denominazione, a.codice_tributo   

LOOP

  codice_fiscale_ente := rec770_f.codice_fiscale_ente;
  cognome_denominazione := rec770_f.cognome_denominazione;
  nome := rec770_f.nome;
  codice_fiscale_percipiente := rec770_f.codice_fiscale_percipiente;
  indirizzo_domicilio_fiscale := rec770_f.indirizzo_domicilio_fiscale;
  cap_domicilio_spedizione := rec770_f.cap_domicilio_spedizione;
  comune_domicilio_fiscale := rec770_f.comune_domicilio_fiscale;
  provincia_domicilio_fiscale := rec770_f.provincia_domicilio_fiscale;
  
  SELECT upper(sdo.onere_desc)
  INTO   descrizione_onere
  FROM   siac_d_onere sdo
  WHERE  sdo.ente_proprietario_id = p_ente_prop_id
  AND    sdo.onere_code = rec770_f.codice_tributo
  AND    now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
  AND    sdo.data_cancellazione IS NULL;
  
  codice_tributo := rec770_f.codice_tributo;
  ammontare_lordo_corrisposto := rec770_f.ammontare_lordo_corrisposto;
  altre_somme_no_ritenute := rec770_f.altre_somme_no_ritenute;
  imponibile := rec770_f.ammontare_lordo_corrisposto - rec770_f.altre_somme_no_ritenute;
  imposta := rec770_f.ritenute_operate;
  ritenute_operate := rec770_f.ritenute_operate;
  -- detrazioni := 0;
  netto := rec770_f.ammontare_lordo_corrisposto - rec770_f.ritenute_operate;
  responsabile_amministrativo := '';

  return next;
      
  codice_fiscale_ente := '';
  cognome_denominazione := '';
  nome := '';
  codice_fiscale_percipiente := '';
  indirizzo_domicilio_fiscale := '';
  cap_domicilio_spedizione := '';
  comune_domicilio_fiscale := '';
  provincia_domicilio_fiscale := '';
  descrizione_onere := '';
  codice_tributo := '';
  ammontare_lordo_corrisposto := 0;
  altre_somme_no_ritenute := 0;
  imponibile := 0;
  ritenute_operate := 0;
  detrazioni := 0;
  netto := 0;
  responsabile_amministrativo := '';

END LOOP;

raise notice 'fine OK';
raise notice '4: %', clock_timestamp()::varchar; 

    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per dati 770';
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