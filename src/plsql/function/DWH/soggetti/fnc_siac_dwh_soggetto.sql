/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_soggetto (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
rec_soggetto_id record;
rec_indirizzo record;
rec_recapito record;
rec_attr record;
-- Variabili per campi estratti dal cursore rec_soggetto_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_soggetto_code VARCHAR := null;
v_soggetto_tipo_desc VARCHAR := null;
v_soggetto_stato_desc VARCHAR := null;
v_ragione_sociale VARCHAR := null;
v_partita_iva VARCHAR := null;
v_codice_fiscale VARCHAR := null;
v_codice_fiscale_estero VARCHAR := null;
v_nome VARCHAR := null;
v_cognome VARCHAR := null;
v_sesso VARCHAR := null;
v_nascita_data TIMESTAMP := null;
v_comune_nascita VARCHAR := null;
v_codice_istat_comune_nascita VARCHAR := null;
v_codice_catastale_comune_nascita VARCHAR := null;
v_provincia_nascita VARCHAR := null;
v_nazione_nascita VARCHAR := null;
v_indirizzo_principale VARCHAR := null;
v_cap_indirizzo_principale VARCHAR := null;
v_comune_indirizzo_principale VARCHAR := null;
v_codice_istat_comune_indirizzo_principale VARCHAR := null;
v_codice_catastale_comune_indirizzo_principale VARCHAR := null;
v_provincia_indirizzo_principale VARCHAR := null;
v_nazione_indirizzo_principale VARCHAR := null;
v_indirizzo_domicilio_fiscale VARCHAR := null;
v_cap_indirizzo_domicilio_fiscale VARCHAR := null;
v_comune_domicilio_fiscale VARCHAR := null;
v_codice_istat_comune_indirizzo_domicilio_fiscale VARCHAR := null;
v_codice_catastale_comune_indirizzo_domicilio_fiscale VARCHAR := null;
v_provincia_domicilio_fiscale VARCHAR := null;
v_nazione_domicilio_fiscale VARCHAR := null;
v_indirizzo_residenza VARCHAR := null;
v_cap_indirizzo_residenza VARCHAR := null;
v_comune_residenza VARCHAR := null;
v_codice_istat_comune_indirizzo_residenza VARCHAR := null;
v_codice_catastale_comune_indirizzo_residenza VARCHAR := null;
v_provincia_residenza VARCHAR := null;
v_nazione_residenza VARCHAR := null;
v_indirizzo_sede_legale VARCHAR := null;
v_cap_indirizzo_sede_legale VARCHAR := null;
v_comune_sede_legale VARCHAR := null;
v_codice_istat_comune_indirizzo_sede_legale VARCHAR := null;
v_codice_catastale_comune_indirizzo_sede_legale VARCHAR := null;
v_provincia_sede_legale VARCHAR := null;
v_nazione_sede_legale VARCHAR := null;
v_indirizzo_sede_amministrativa VARCHAR := null;
v_cap_indirizzo_sede_amministrativa VARCHAR := null;
v_comune_sede_amministrativa VARCHAR := null;
v_codice_istat_comune_indirizzo_sede_amministrativa VARCHAR := null;
v_codice_catastale_comune_indirizzo_sede_amministrativa VARCHAR := null;
v_provincia_sede_amministrativa VARCHAR := null;
v_nazione_sede_amministrativa VARCHAR := null;
v_indirizzo_sede_operativa VARCHAR := null;
v_cap_indirizzo_sede_operativa VARCHAR := null;
v_comune_sede_operativa VARCHAR := null;
v_codice_istat_comune_indirizzo_sede_operativa VARCHAR := null;
v_codice_catastale_comune_indirizzo_sede_operativa VARCHAR := null;
v_provincia_sede_operativa VARCHAR := null;
v_nazione_sede_operativa VARCHAR := null;
v_telefono VARCHAR := null;
v_cellulare VARCHAR := null;
v_fax VARCHAR := null;
v_email VARCHAR := null;
v_pec VARCHAR := null;
v_sito_web VARCHAR := null;
v_soggetto_recapito VARCHAR := null;
v_avviso VARCHAR := null;
v_NoteSoggetto VARCHAR := null;
v_Matricola VARCHAR := null;
v_soggetto_classe_desc VARCHAR := null;
v_sede_secondaria VARCHAR := null;
v_codice_soggetto_principale VARCHAR := null;
v_soggetto_principale VARCHAR := null;

v_comune_desc VARCHAR := null;
v_comune_istat_code VARCHAR := null;
v_comune_belfiore_catastale_code VARCHAR := null;
v_provincia_desc VARCHAR := null;
v_nazione_desc VARCHAR := null;
v_indirizzo_tipo_code VARCHAR := null;
v_principale VARCHAR := null;
v_zip_code VARCHAR := null;
v_indirizzo VARCHAR := null;
v_via_tipo_desc VARCHAR := null;
v_toponimo VARCHAR := null;
v_numero_civico VARCHAR := null;
v_frazione VARCHAR := null;
v_interno VARCHAR := null;
v_recapito_desc VARCHAR := null;
v_recapito_modo_code VARCHAR := null;
v_flag_attributo VARCHAR := null;

v_comune_id_nascita INTEGER := null;
v_soggetto_id INTEGER := null;
v_comune_id INTEGER := null;
v_comune_id_gen INTEGER := null;
v_soggetto_id_principale INTEGER := null;
v_via_tipo_id INTEGER := null;

v_user_table varchar;
params varchar;
fnc_eseguita integer;

-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc varchar:=null;
v_soggetto_fonte_durc_automatica varchar:=null;
v_soggetto_note_durc varchar:=null;
v_soggetto_fine_validita_durc timestamp:=null;
v_soggetto_fonte_durc_manuale_code varchar:=null;
v_soggetto_fonte_durc_manuale_desc varchar:=null;

BEGIN

select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_soggetto';


-- 13.03.2020 Sofia jira 	SIAC-7513 
fnc_eseguita:=0;
if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_soggetto',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico soggetto (FNC_SIAC_DWH_SOGGETTO) - '||clock_timestamp();
RETURN NEXT;


esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_soggetto
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;
-- Ciclo per estrarre i dati relativi ad un soggetto_id
FOR rec_soggetto_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, ts.soggetto_code, dst.soggetto_tipo_desc,
       dss.soggetto_stato_desc, tpg.ragione_sociale, ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
       tpf.nome, tpf.cognome, tpf.sesso, tpf.nascita_data, dsc.soggetto_classe_desc,
       tpf.comune_id_nascita, ts.soggetto_id,
       -- 03/07/2017: aggiunto il campo soggetto_desc
       ts.soggetto_desc,
       -- 05.12.2018 Sofia SIAC-6261
       ts.soggetto_tipo_fonte_durc,
       substring(ts.soggetto_fonte_durc_automatica from 1 for 500) soggetto_fonte_durc_automatica,
       substring(ts.soggetto_note_durc from 1 for 500) soggetto_note_durc,
       ts.soggetto_fine_validita_durc::timestamp soggetto_fine_validita_durc,
       ts.soggetto_fonte_durc_manuale_classif_id
FROM siac.siac_t_soggetto ts
INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = ts.ente_proprietario_id
                                             AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
                                             AND tep.data_cancellazione IS NULL
INNER JOIN siac.siac_d_ambito da ON da.ambito_id = ts.ambito_id
                                             AND p_data BETWEEN da.validita_inizio AND COALESCE(da.validita_fine, p_data)
                                             AND da.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                        AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                        AND rst.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id= rst.soggetto_tipo_id
                                        AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                        AND dst.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                         AND rss.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                         AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                         AND dss.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                            AND tpg.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                         AND tpf.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_classe rsc ON rsc.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN rsc.validita_inizio AND COALESCE(rsc.validita_fine, p_data)
                                         AND rsc.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_classe dsc ON dsc.soggetto_classe_id = rsc.soggetto_classe_id
                                         AND p_data BETWEEN dsc.validita_inizio AND COALESCE(dsc.validita_fine, p_data)
                                         AND dsc.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND   da.ambito_code = 'AMBITO_FIN'
AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND ts.data_cancellazione IS NULL
order by ts.soggetto_id desc
--limit 3000
LOOP

v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_soggetto_code := null;
v_soggetto_tipo_desc := null;
v_soggetto_stato_desc := null;
v_ragione_sociale := null;
v_partita_iva := null;
v_codice_fiscale := null;
v_codice_fiscale_estero := null;
v_nome := null;
v_cognome := null;
v_sesso := null;
v_nascita_data := null;
v_indirizzo_principale := null;
v_cap_indirizzo_principale := null;
v_comune_indirizzo_principale := null;
v_codice_istat_comune_indirizzo_principale := null;
v_codice_catastale_comune_indirizzo_principale := null;
v_provincia_indirizzo_principale := null;
v_nazione_indirizzo_principale := null;
v_indirizzo_domicilio_fiscale := null;
v_cap_indirizzo_domicilio_fiscale := null;
v_comune_domicilio_fiscale := null;
v_codice_istat_comune_indirizzo_domicilio_fiscale := null;
v_codice_catastale_comune_indirizzo_domicilio_fiscale := null;
v_provincia_domicilio_fiscale := null;
v_nazione_domicilio_fiscale := null;
v_indirizzo_residenza := null;
v_cap_indirizzo_residenza := null;
v_comune_residenza := null;
v_codice_istat_comune_indirizzo_residenza := null;
v_codice_catastale_comune_indirizzo_residenza := null;
v_provincia_residenza := null;
v_nazione_residenza := null;
v_indirizzo_sede_legale := null;
v_cap_indirizzo_sede_legale := null;
v_comune_sede_legale := null;
v_codice_istat_comune_indirizzo_sede_legale := null;
v_codice_catastale_comune_indirizzo_sede_legale := null;
v_provincia_sede_legale := null;
v_nazione_sede_legale := null;
v_indirizzo_sede_amministrativa := null;
v_cap_indirizzo_sede_amministrativa := null;
v_comune_sede_amministrativa := null;
v_codice_istat_comune_indirizzo_sede_amministrativa := null;
v_codice_catastale_comune_indirizzo_sede_amministrativa := null;
v_provincia_sede_amministrativa := null;
v_nazione_sede_amministrativa := null;
v_indirizzo_sede_operativa := null;
v_cap_indirizzo_sede_operativa := null;
v_comune_sede_operativa := null;
v_codice_istat_comune_indirizzo_sede_operativa := null;
v_codice_catastale_comune_indirizzo_sede_operativa := null;
v_provincia_sede_operativa := null;
v_nazione_sede_operativa := null;
v_telefono := null;
v_cellulare := null;
v_fax := null;
v_email := null;
v_pec := null;
v_sito_web := null;
v_soggetto_recapito := null;
v_avviso := null;
v_soggetto_classe_desc := null;
v_sede_secondaria := null;
v_codice_soggetto_principale := null;
v_soggetto_principale := null;

v_comune_id_nascita := null;
v_soggetto_id := null;
v_soggetto_id_principale := null;

v_flag_attributo := null;

-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc:=null;
v_soggetto_fonte_durc_automatica:=null;
v_soggetto_note_durc:=null;
v_soggetto_fine_validita_durc:=null;
v_soggetto_fonte_durc_manuale_code:=null;
v_soggetto_fonte_durc_manuale_desc:=null;

v_ente_proprietario_id := rec_soggetto_id.ente_proprietario_id;
v_ente_denominazione := rec_soggetto_id.ente_denominazione;
v_soggetto_code := rec_soggetto_id.soggetto_code;
v_soggetto_tipo_desc := rec_soggetto_id.soggetto_tipo_desc;
v_soggetto_stato_desc := rec_soggetto_id.soggetto_stato_desc;
v_ragione_sociale := rec_soggetto_id.ragione_sociale;
v_partita_iva := rec_soggetto_id.partita_iva;
v_codice_fiscale := rec_soggetto_id.codice_fiscale;
v_codice_fiscale_estero := rec_soggetto_id.codice_fiscale_estero;
v_nome := rec_soggetto_id.nome;
v_cognome := rec_soggetto_id.cognome;
v_sesso := rec_soggetto_id.sesso;
v_nascita_data := rec_soggetto_id.nascita_data;
v_soggetto_classe_desc := rec_soggetto_id.soggetto_classe_desc;

v_comune_id_nascita := rec_soggetto_id.comune_id_nascita;
v_soggetto_id := rec_soggetto_id.soggetto_id;


-- 05.12.2018 Sofia SIAC-6261
v_soggetto_tipo_fonte_durc:=rec_soggetto_id.soggetto_tipo_fonte_durc;
v_soggetto_fonte_durc_automatica:=rec_soggetto_id.soggetto_fonte_durc_automatica;
v_soggetto_note_durc:=rec_soggetto_id.soggetto_note_durc;
v_soggetto_fine_validita_durc:=rec_soggetto_id.soggetto_fine_validita_durc;


if rec_soggetto_id.soggetto_fonte_durc_manuale_classif_id is not null then
	select c.classif_code, c.classif_desc
    into   v_soggetto_fonte_durc_manuale_code,v_soggetto_fonte_durc_manuale_desc
	from siac_t_class c, siac_d_class_tipo tipo
    where c.classif_id=rec_soggetto_id.soggetto_fonte_durc_manuale_classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code in ('CDC','CDR')
    and   c.data_cancellazione is null;

end if;


esito:= '  Inizio ciclo soggetto - soggetto_id ('||v_soggetto_id||') - '||clock_timestamp();
return next;
-- Ciclo pre estrarre l'indirizzo del soggetto
FOR rec_indirizzo IN
SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
       tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
FROM siac.siac_t_indirizzo_soggetto tis
INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                    AND p_data BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, p_data)
                                                    AND rist.data_cancellazione IS NULL
INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                          AND p_data BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, p_data)
                                          AND dit.data_cancellazione IS NULL
WHERE tis.soggetto_id = v_soggetto_id
AND p_data BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, p_data)
AND tis.data_cancellazione IS NULL
UNION
SELECT NULL, 'NASCITA', NULL, NULL, NULL, NULL, NULL, NULL, NULL

LOOP

v_comune_id := null;
v_comune_id_gen := null;
v_indirizzo_tipo_code := null;

v_principale := null;
v_zip_code := null;
v_comune_desc := null;
v_comune_istat_code := null;
v_comune_belfiore_catastale_code := null;
v_provincia_desc := null;
v_nazione_desc := null;
v_indirizzo := null;
v_via_tipo_desc := null;
v_toponimo := null;
v_numero_civico := null;
v_frazione := null;
v_interno := null;
v_via_tipo_id := null;

v_comune_id := rec_indirizzo.comune_id;
v_indirizzo_tipo_code := rec_indirizzo.indirizzo_tipo_code;
v_principale := rec_indirizzo.principale;
v_zip_code := rec_indirizzo.zip_code;

v_toponimo := rec_indirizzo.toponimo;
v_numero_civico := rec_indirizzo.numero_civico;
v_frazione := rec_indirizzo.frazione;
v_interno := rec_indirizzo.interno;
v_via_tipo_id := rec_indirizzo.via_tipo_id;
-- Estrazione tipo via
SELECT dvt.via_tipo_desc
INTO v_via_tipo_desc
FROM siac.siac_d_via_tipo dvt
WHERE dvt.via_tipo_id = v_via_tipo_id
AND p_data BETWEEN dvt.validita_inizio AND COALESCE(dvt.validita_fine, p_data)
AND dvt.data_cancellazione IS NULL;

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

v_indirizzo := UPPER(v_indirizzo);

IF v_indirizzo_tipo_code = 'NASCITA' THEN
   v_comune_id_gen := v_comune_id_nascita;
ELSE
   v_comune_id_gen := v_comune_id;
END IF;
-- Estrazione dati comune
SELECT tc.comune_desc, tc.comune_istat_code, tc.comune_belfiore_catastale_code, tp.provincia_desc, tn.nazione_desc
INTO  v_comune_desc, v_comune_istat_code, v_comune_belfiore_catastale_code, v_provincia_desc, v_nazione_desc
FROM siac.siac_t_comune tc
LEFT JOIN siac.siac_r_comune_provincia rcp ON rcp.comune_id = tc.comune_id
                                           AND p_data BETWEEN rcp.validita_inizio AND COALESCE(rcp.validita_fine, p_data)
                                           AND rcp.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_provincia tp ON tp.provincia_id = rcp.provincia_id
                                   AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
                                   AND tp.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_nazione tn ON tn.nazione_id = tc.nazione_id
                                 AND p_data BETWEEN tn.validita_inizio AND COALESCE(tn.validita_fine, p_data)
                                 AND tn.data_cancellazione IS NULL
WHERE tc.comune_id = v_comune_id_gen
AND p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
AND tc.data_cancellazione IS NULL;

IF v_principale = 'S' THEN
   v_indirizzo_principale := v_indirizzo;
   v_cap_indirizzo_principale := v_zip_code;
   v_comune_indirizzo_principale := v_comune_desc;
   v_codice_istat_comune_indirizzo_principale := v_comune_istat_code;
   v_codice_catastale_comune_indirizzo_principale := v_comune_belfiore_catastale_code;
   v_provincia_indirizzo_principale := v_provincia_desc;
   v_nazione_indirizzo_principale := v_nazione_desc;
END IF;

IF  v_indirizzo_tipo_code = 'NASCITA' THEN
    v_comune_nascita := v_comune_desc;
    v_codice_istat_comune_nascita := v_comune_istat_code;
    v_codice_catastale_comune_nascita := v_comune_belfiore_catastale_code;
    v_provincia_nascita := v_provincia_desc;
    v_nazione_nascita := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'DOMICILIO' THEN
	v_indirizzo_domicilio_fiscale := v_indirizzo;
    v_cap_indirizzo_domicilio_fiscale := v_zip_code;
    v_comune_domicilio_fiscale := v_comune_desc;
    v_codice_istat_comune_indirizzo_domicilio_fiscale := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_domicilio_fiscale := v_comune_belfiore_catastale_code;
    v_provincia_domicilio_fiscale := v_provincia_desc;
    v_nazione_domicilio_fiscale := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'RESIDENZA' THEN
	v_indirizzo_residenza := v_indirizzo;
    v_cap_indirizzo_residenza := v_zip_code;
    v_comune_residenza := v_comune_desc;
    v_codice_istat_comune_indirizzo_residenza := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_residenza := v_comune_belfiore_catastale_code;
    v_provincia_residenza := v_provincia_desc;
    v_nazione_residenza := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'SEDE_LEGALE' THEN
	v_indirizzo_sede_legale := v_indirizzo;
    v_cap_indirizzo_sede_legale := v_zip_code;
    v_comune_sede_legale := v_comune_desc;
    v_codice_istat_comune_indirizzo_sede_legale := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_sede_legale := v_comune_belfiore_catastale_code;
    v_provincia_sede_legale := v_provincia_desc;
    v_nazione_sede_legale := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'SEDE_AMM' THEN
	v_indirizzo_sede_amministrativa := v_indirizzo;
    v_cap_indirizzo_sede_amministrativa := v_zip_code;
    v_comune_sede_amministrativa := v_comune_desc;
    v_codice_istat_comune_indirizzo_sede_amministrativa := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_sede_amministrativa := v_comune_belfiore_catastale_code;
    v_provincia_sede_amministrativa := v_provincia_desc;
    v_nazione_sede_amministrativa := v_nazione_desc;
ELSIF  v_indirizzo_tipo_code = 'SEDE_OPERATIVA' THEN
	v_indirizzo_sede_operativa := v_indirizzo;
    v_cap_indirizzo_sede_operativa := v_zip_code;
    v_comune_sede_operativa := v_comune_desc;
    v_codice_istat_comune_indirizzo_sede_operativa := v_comune_istat_code;
    v_codice_catastale_comune_indirizzo_sede_operativa := v_comune_belfiore_catastale_code;
    v_provincia_sede_operativa := v_provincia_desc;
    v_nazione_sede_operativa := v_nazione_desc;
END IF;

END LOOP;
-- Ciclo per estrarre il recapito di un soggetto
FOR rec_recapito IN
SELECT trs.recapito_desc, drm.recapito_modo_code, trs.avviso
FROM siac.siac_t_recapito_soggetto trs
INNER JOIN siac.siac_d_recapito_modo drm ON drm.recapito_modo_id = trs.recapito_modo_id
                                         AND p_data BETWEEN drm.validita_inizio AND COALESCE(drm.validita_fine, p_data)
                                         AND drm.data_cancellazione IS NULL
WHERE trs.soggetto_id = v_soggetto_id
AND p_data BETWEEN trs.validita_inizio AND COALESCE(trs.validita_fine, p_data)
AND trs.data_cancellazione IS NULL

LOOP
  v_recapito_desc := null;
  v_recapito_modo_code := null;

  v_recapito_desc := rec_recapito.recapito_desc;
  v_recapito_modo_code := rec_recapito.recapito_modo_code;

  IF rec_recapito.avviso = 'S' THEN
     v_avviso := rec_recapito.avviso;
  END IF;

  IF v_recapito_modo_code = 'telefono' THEN
     v_telefono := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'cellulare' THEN
     v_cellulare := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'fax' THEN
     v_fax := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'email' THEN
     v_email := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'PEC' THEN
     v_pec := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'sito' THEN
     v_sito_web := v_recapito_desc;
  ELSIF v_recapito_modo_code = 'soggetto' THEN
     v_soggetto_recapito := v_recapito_desc;
  END IF;

END LOOP;
-- Sezione per gli attributi
FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
FROM   siac.siac_r_soggetto_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rsa.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rsa.soggetto_id = v_soggetto_id
AND    rsa.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'NoteSoggetto' THEN
     v_NoteSoggetto := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Matricola' THEN
     v_Matricola := v_flag_attributo;
  END IF;

END LOOP;
-- Sezione per estrarre la sede secondaria
SELECT rsr.soggetto_id_da
INTO v_soggetto_id_principale
FROM siac.siac_r_soggetto_relaz rsr, siac.siac_d_relaz_tipo drt
WHERE rsr.relaz_tipo_id = drt.relaz_tipo_id
AND   drt.relaz_tipo_code  = 'SEDE_SECONDARIA'
AND   rsr.soggetto_id_a = v_soggetto_id
AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
AND   p_data BETWEEN drt.validita_inizio AND COALESCE(drt.validita_fine, p_data)
AND   rsr.data_cancellazione IS NULL
AND   drt.data_cancellazione IS NULL;

IF  v_soggetto_id_principale IS NOT NULL THEN
    v_sede_secondaria := 'S';

    -- 03/07/2017: Modifiche per SIAC-5039.
    --   Se esiste la sede secondaria, la ragione sociale viene
    --   assegnata con il contenuto della descrizione del soggetto.
	if v_ragione_sociale IS NULL THEN
    	v_ragione_sociale:=rec_soggetto_id.soggetto_desc;
    end if;

    SELECT ts.soggetto_code,
           CASE
              WHEN dst.soggetto_tipo_code in ('PF', 'PFI') THEN
                   tpf.nome||' '||tpf.cognome
              ELSE
                   tpg.ragione_sociale
           END  soggetto_principale
    INTO v_codice_soggetto_principale, v_soggetto_principale
    FROM siac.siac_t_soggetto ts
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id= rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE ts.soggetto_id = v_soggetto_id_principale
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

END IF;


  INSERT INTO siac.siac_dwh_soggetto
  ( ente_proprietario_id,
    ente_denominazione,
    soggetto_id,
    cod_soggetto,
    tipo_soggetto,
    stato_soggetto,
    ragione_sociale,
    p_iva,
    cf,
    cf_estero,
    nome,
    cognome,
    sesso,
    data_nascita,
    comune_nascita,
    codistat_comune_nascita,
    codcatastale_comune_nascita,
    provincia_nascita,
    nazione_nascita,
    indirizzo_principale,
    cap_indirizzo_principale,
    comune_indirizzo_principale,
    codistat_comune_ind_princ,
    codcatastale_comune_ind_princ,
    provincia_indirizzo_principale,
    nazione_indirizzo_principale,
    indirizzo_domicilio_fiscale,
    cap_domicilio_fiscale,
    comune_domicilio_fiscale,
    codistat_comune_domfiscale,
    codcatastale_comune_domfiscale,
    provincia_domicilio_fiscale,
    nazione_domicilio_fiscale,
    indirizzo_residenza,
    cap_residenza,
    comune_residenza,
    codistat_comune_residenza,
    codcatastale_comune_residenza,
    provincia_residenza,
    nazione_residenza,
    indirizzo_sede_legale,
    cap_sede_legale,
    comune_sede_legale,
    codistat_comune_sedelegale,
    codcatastale_comune_sedelegale,
    provincia_sede_legale,
    nazione_sede_legale,
    indirizzo_sede_amministrativa ,
    cap_sede_amministrativa,
    comune_sede_amministrativa,
    codistat_comune_sede_amm,
    codcatastale_comune_sede_amm,
    provincia_sede_amministrativa,
    nazione_sede_amministrativa,
    indirizzo_sede_operativa,
    cap_sede_operativa,
    comune_sede_operativa,
    codistat_comune_sede_oper ,
    codcatastale_comune_sede_oper,
    provincia_sede_operativa,
    nazione_sede_operativa,
    telefono,
    cellulare,
    fax,
    email,
    pec,
    sito_web,
    soggetto_recapito,
    avviso,
    note,
    matricola_hrspi,
    classe_soggetto,
    sede_secondaria,
    soggetto_id_principale,
    codice_soggetto_principale,
    soggetto_principale,
    -- 05.12.2018  Sofia Sofia SIAC-6261
    soggetto_tipo_fonte_durc,
    soggetto_fonte_durc_automatica,
    soggetto_note_durc,
    soggetto_fine_validita_durc,
    soggetto_fonte_durc_manuale_code,
    soggetto_fonte_durc_manuale_desc
  )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_soggetto_id,
          v_soggetto_code,
          v_soggetto_tipo_desc,
          v_soggetto_stato_desc,
          v_ragione_sociale,
          v_partita_iva,
          v_codice_fiscale,
          v_codice_fiscale_estero,
          v_nome,
          v_cognome,
          v_sesso,
          v_nascita_data,
          v_comune_nascita,
          v_codice_istat_comune_nascita,
          v_codice_catastale_comune_nascita,
          v_provincia_nascita,
          v_nazione_nascita,
          v_indirizzo_principale,
          v_cap_indirizzo_principale,
          v_comune_indirizzo_principale,
          v_codice_istat_comune_indirizzo_principale,
          v_codice_catastale_comune_indirizzo_principale,
          v_provincia_indirizzo_principale,
          v_nazione_indirizzo_principale,
          v_indirizzo_domicilio_fiscale,
          v_cap_indirizzo_domicilio_fiscale,
          v_comune_domicilio_fiscale,
          v_codice_istat_comune_indirizzo_domicilio_fiscale ,
          v_codice_catastale_comune_indirizzo_domicilio_fiscale,
          v_provincia_domicilio_fiscale,
          v_nazione_domicilio_fiscale,
          v_indirizzo_residenza,
          v_cap_indirizzo_residenza,
          v_comune_residenza,
          v_codice_istat_comune_indirizzo_residenza,
          v_codice_catastale_comune_indirizzo_residenza,
          v_provincia_residenza,
          v_nazione_residenza,
          v_indirizzo_sede_legale,
          v_cap_indirizzo_sede_legale,
          v_comune_sede_legale,
          v_codice_istat_comune_indirizzo_sede_legale,
          v_codice_catastale_comune_indirizzo_sede_legale,
          v_provincia_sede_legale,
          v_nazione_sede_legale,
          v_indirizzo_sede_amministrativa,
          v_cap_indirizzo_sede_amministrativa,
          v_comune_sede_amministrativa,
          v_codice_istat_comune_indirizzo_sede_amministrativa,
          v_codice_catastale_comune_indirizzo_sede_amministrativa,
          v_provincia_sede_amministrativa,
          v_nazione_sede_amministrativa,
          v_indirizzo_sede_operativa,
          v_cap_indirizzo_sede_operativa,
          v_comune_sede_operativa,
          v_codice_istat_comune_indirizzo_sede_operativa,
          v_codice_catastale_comune_indirizzo_sede_operativa,
          v_provincia_sede_operativa,
          v_nazione_sede_operativa,
          v_telefono,
          v_cellulare,
          v_fax,
          v_email,
          v_pec,
          v_sito_web,
          v_soggetto_recapito,
          v_avviso,
          v_NoteSoggetto,
          v_Matricola,
          v_soggetto_classe_desc,
          v_sede_secondaria,
          v_soggetto_id_principale,
          v_codice_soggetto_principale,
          v_soggetto_principale,
          -- 05.12.2018  Sofia Sofia SIAC-6261
          v_soggetto_tipo_fonte_durc,
	      v_soggetto_fonte_durc_automatica,
	      v_soggetto_note_durc,
	      v_soggetto_fine_validita_durc,
	      v_soggetto_fonte_durc_manuale_code,
	      v_soggetto_fonte_durc_manuale_desc
         );

esito:= '  Fine ciclo soggetto - soggetto_id ('||v_soggetto_id||') - '||clock_timestamp();
return next;
END LOOP;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico soggetto (FNC_SIAC_DWH_SOGGETTO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;