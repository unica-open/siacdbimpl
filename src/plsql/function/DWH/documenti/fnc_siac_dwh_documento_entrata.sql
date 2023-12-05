/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_entrata (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_doc_id record;
rec_subdoc_id record;
rec_attr record;
rec_classif_id record;
rec_classif_id_attr record;
-- Variabili per campi estratti dal cursore rec_doc_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno_doc INTEGER := null;
v_num_doc VARCHAR := null;
v_stato_sdi VARCHAR(2) := null; -- SIAC-6565
v_desc_doc VARCHAR := null;
v_importo_doc NUMERIC := null;
v_beneficiario_multiplo_doc VARCHAR := null;
v_data_emissione_doc TIMESTAMP := null;
v_data_scadenza_doc TIMESTAMP := null;
v_codice_bollo_doc VARCHAR := null;
v_desc_codice_bollo_doc VARCHAR := null;
v_collegato_cec_doc VARCHAR := null;
v_cod_pcc_doc VARCHAR := null;
v_desc_pcc_doc VARCHAR := null;
v_cod_ufficio_doc VARCHAR := null;
v_desc_ufficio_doc VARCHAR := null;
v_cod_stato_doc VARCHAR := null;
v_desc_stato_doc VARCHAR := null;
v_cod_gruppo_doc VARCHAR := null;
v_desc_gruppo_doc VARCHAR := null;
v_cod_famiglia_doc VARCHAR := null;
v_desc_famiglia_doc VARCHAR := null;
v_cod_tipo_doc VARCHAR := null;
v_desc_tipo_doc VARCHAR := null;
v_sogg_id_doc INTEGER := null;
v_cod_sogg_doc VARCHAR := null;
v_tipo_sogg_doc VARCHAR := null;
v_stato_sogg_doc VARCHAR := null;
v_rag_sociale_sogg_doc VARCHAR := null;
v_p_iva_sogg_doc VARCHAR := null;
v_cf_sogg_doc VARCHAR := null;
v_cf_estero_sogg_doc VARCHAR := null;
v_nome_sogg_doc VARCHAR := null;
v_cognome_sogg_doc VARCHAR := null;
--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc VARCHAR := null;
-- Variabili per campi estratti dal cursore rec_subdoc_id
v_num_subdoc INTEGER := null;
v_desc_subdoc VARCHAR := null;
v_importo_subdoc NUMERIC := null;
v_num_reg_iva_subdoc VARCHAR := null;
v_data_scadenza_subdoc TIMESTAMP := null;
v_convalida_manuale_subdoc VARCHAR := null;
v_importo_da_dedurre_subdoc NUMERIC := null;
v_splitreverse_importo_subdoc NUMERIC := null;
v_pagato_cec_subdoc VARCHAR := null;
v_data_pagamento_cec_subdoc TIMESTAMP := null;
v_anno_atto_amministrativo VARCHAR := null;
v_num_atto_amministrativo VARCHAR := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_cod_tipo_atto_amministrativo VARCHAR := null;
v_desc_tipo_atto_amministrativo VARCHAR := null;
v_cod_stato_atto_amministrativo VARCHAR := null;
v_desc_stato_atto_amministrativo VARCHAR := null;
v_causale_atto_allegato VARCHAR := null;
v_altri_allegati_atto_allegato VARCHAR := null;
v_dati_sensibili_atto_allegato VARCHAR := null;
v_data_scadenza_atto_allegato TIMESTAMP := null;
v_note_atto_allegato VARCHAR := null;
v_annotazioni_atto_allegato VARCHAR := null;
v_pratica_atto_allegato VARCHAR := null;
v_resp_amm_atto_allegato VARCHAR := null;
v_resp_contabile_atto_allegato VARCHAR := null;
v_anno_titolario_atto_allegato INTEGER := null;
v_num_titolario_atto_allegato VARCHAR := null;
v_vers_invio_firma_atto_allegato INTEGER := null;
v_cod_stato_atto_allegato VARCHAR := null;
v_desc_stato_atto_allegato VARCHAR := null;
v_anno_elenco_doc INTEGER := null;
v_num_elenco_doc INTEGER := null;
v_data_trasmissione_elenco_doc TIMESTAMP := null;
v_tot_quote_entrate_elenco_doc NUMERIC := null;
v_tot_quote_spese_elenco_doc NUMERIC := null;
v_tot_da_pagare_elenco_doc NUMERIC := null;
v_tot_da_incassare_elenco_doc NUMERIC := null;
v_cod_stato_elenco_doc VARCHAR := null;
v_desc_stato_elenco_doc VARCHAR := null;
v_note_tesoriere_subdoc VARCHAR := null;
v_cod_distinta_subdoc VARCHAR := null;
v_desc_distinta_subdoc VARCHAR := null;
v_tipo_commissione_subdoc VARCHAR := null;
v_conto_tesoreria_subdoc VARCHAR := null;
-- Variabili per i soggetti legati all'atto allegato
v_sogg_id_atto_allegato INTEGER := null;
v_cod_sogg_atto_allegato VARCHAR := null;
v_tipo_sogg_atto_allegato VARCHAR := null;
v_stato_sogg_atto_allegato VARCHAR := null;
v_rag_sociale_sogg_atto_allegato VARCHAR := null;
v_p_iva_sogg_atto_allegato VARCHAR := null;
v_cf_sogg_atto_allegato VARCHAR := null;
v_cf_estero_sogg_atto_allegato VARCHAR := null;
v_nome_sogg_atto_allegato VARCHAR := null;
v_cognome_sogg_atto_allegato VARCHAR := null;
-- Variabili per i classificatori
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;
v_cod_tipo_avviso VARCHAR := null;
v_desc_tipo_avviso VARCHAR := null;
-- Variabili per gli attributi
v_rilevante_iva VARCHAR := null;
v_ordinativo_singolo VARCHAR := null;
v_ordinativo_manuale VARCHAR := null;
v_esproprio VARCHAR := null;
v_note VARCHAR := null;
v_avviso VARCHAR := null;
-- Variabili per i soggetti legati al subdoc
v_cod_sogg_subdoc VARCHAR := null;
v_tipo_sogg_subdoc VARCHAR := null;
v_stato_sogg_subdoc VARCHAR := null;
v_rag_sociale_sogg_subdoc VARCHAR := null;
v_p_iva_sogg_subdoc VARCHAR := null;
v_cf_sogg_subdoc VARCHAR := null;
v_cf_estero_sogg_subdoc VARCHAR := null;
v_nome_sogg_subdoc VARCHAR := null;
v_cognome_sogg_subdoc VARCHAR := null;
-- Variabili per gli ordinamenti legati ai documenti
v_bil_anno_ord VARCHAR := null;
v_anno_ord INTEGER := null;
v_num_ord NUMERIC := null;
v_num_subord VARCHAR := null;
-- Variabile per la sede secondaria
v_sede_secondaria_subdoc VARCHAR := null;
-- Variabili per gli accertamenti
v_bil_anno VARCHAR := null;
v_anno_accertamento INTEGER := null;
v_num_accertamento NUMERIC := null;
v_cod_accertamento VARCHAR := null;
v_desc_accertamento VARCHAR := null;
v_cod_subaccertamento VARCHAR := null;
v_desc_subaccertamento VARCHAR := null;
-- Variabili per la modalita' di pagamento
v_quietanziante VARCHAR := null;
v_data_nascita_quietanziante TIMESTAMP := null;
v_luogo_nascita_quietanziante VARCHAR := null;
v_stato_nascita_quietanziante VARCHAR := null;
v_bic VARCHAR := null;
v_contocorrente VARCHAR := null;
v_intestazione_contocorrente VARCHAR := null;
v_iban VARCHAR := null;
v_mod_pag_id INTEGER := null;
v_note_mod_pag VARCHAR := null;
v_data_scadenza_mod_pag TIMESTAMP := null;
v_cod_tipo_accredito VARCHAR := null;
v_desc_tipo_accredito VARCHAR := null;
-- Variabili per i soggetti legati alla modalita' pagamento
v_cod_sogg_mod_pag VARCHAR := null;
v_tipo_sogg_mod_pag VARCHAR := null;
v_stato_sogg_mod_pag VARCHAR := null;
v_rag_sociale_sogg_mod_pag VARCHAR := null;
v_p_iva_sogg_mod_pag VARCHAR := null;
v_cf_sogg_mod_pag VARCHAR := null;
v_cf_estero_sogg_mod_pag VARCHAR := null;
v_nome_sogg_mod_pag VARCHAR := null;
v_cognome_sogg_mod_pag VARCHAR := null;
-- Variabili utili per il caricamento
v_doc_id INTEGER := null;
v_subdoc_id INTEGER := null;
v_attoal_id INTEGER := null;
v_attoamm_id INTEGER := null;
v_soggetto_id INTEGER := null;
v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_tipo_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_flag_attributo VARCHAR := null;
v_soggetto_id_principale INTEGER := null;
v_movgest_ts_tipo_code VARCHAR := null;
v_movgest_ts_code VARCHAR := null;
v_soggetto_id_modpag_nocess INTEGER := null;
v_soggetto_id_modpag_cess INTEGER := null;
v_soggetto_id_modpag INTEGER := null;
v_soggrelmpag_id INTEGER := null;
v_pcccod_id INTEGER := null;
v_pccuff_id INTEGER := null;
v_attoamm_tipo_id INTEGER := null;
v_comm_tipo_id INTEGER := null;
--nuova sezione coge 26-09-2016
v_registro_repertorio VARCHAR := null;
v_anno_repertorio VARCHAR := null;
v_num_repertorio VARCHAR := null;
v_data_repertorio VARCHAR := null;
v_arrotondamento VARCHAR := null;
v_data_ricezione_portale VARCHAR := null;
rec_doc_attr record;

v_user_table varchar;
params varchar;
fnc_eseguita integer;


-- 22.05.2018 Sofia siac-6124
v_data_ins_atto_allegato TIMESTAMP := null;
v_data_completa_atto_allegato TIMESTAMP := null;
v_data_convalida_atto_allegato TIMESTAMP := null;
v_data_sosp_atto_allegato TIMESTAMP := null;
v_causale_sosp_atto_allegato varchar := null;
v_data_riattiva_atto_allegato TIMESTAMP := null;

BEGIN


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_documento_entrata' ;


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
'fnc_siac_dwh_documento_entrata',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_documento_entrata
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

-- Ciclo per estrarre doc_id (documenti)
FOR rec_doc_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       td.doc_anno, td.doc_numero, td.doc_desc, td.doc_importo, td.doc_beneficiariomult,
       td.doc_data_emissione, td.doc_data_scadenza, dc.codbollo_code, dc.codbollo_desc,
       td.doc_collegato_cec,
       dds.doc_stato_code, dds.doc_stato_desc, ddg.doc_gruppo_tipo_code, ddg.doc_gruppo_tipo_desc,
       ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc, ddt.doc_tipo_code, ddt.doc_tipo_desc,
       ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
       ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero, tpf.nome, tpf.cognome,
       td.doc_id, td.pcccod_id, td.pccuff_id, ts.soggetto_id,
       td.doc_contabilizza_genpcc, td.stato_sdi
FROM siac.siac_t_doc td
INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = td.ente_proprietario_id
                                             AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
                                             AND tep.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_tipo ddt ON ddt.doc_tipo_id = td.doc_tipo_id
                                    AND p_data BETWEEN ddt.validita_inizio AND COALESCE(ddt.validita_fine, p_data)
                                    AND ddt.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_fam_tipo ddft ON ddft.doc_fam_tipo_id = ddt.doc_fam_tipo_id
                                         AND p_data BETWEEN ddft.validita_inizio AND COALESCE(ddft.validita_fine, p_data)
                                         AND ddft.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_gruppo ddg ON ddg.doc_gruppo_tipo_id = ddt.doc_gruppo_tipo_id
                                     AND p_data BETWEEN ddg.validita_inizio AND COALESCE(ddg.validita_fine, p_data)
                                     AND ddg.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_codicebollo dc ON dc.codbollo_id = td.codbollo_id
LEFT JOIN siac.siac_r_doc_stato rds ON rds.doc_id = td.doc_id
                                    AND p_data BETWEEN rds.validita_inizio AND COALESCE(rds.validita_fine, p_data)
                                    AND rds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_stato dds ON dds.doc_stato_id = rds.doc_stato_id
                                    AND p_data BETWEEN dds.validita_inizio AND COALESCE(dds.validita_fine, p_data)
                                    AND dds.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_doc_sog srds ON srds.doc_id = td.doc_id
                                   AND p_data BETWEEN srds.validita_inizio AND COALESCE(srds.validita_fine, p_data)
                                   AND srds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = srds.soggetto_id
                                  AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
                                  AND ts.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                        AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                        AND rst.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
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
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND ddft.doc_fam_tipo_code in ('E','IE')
AND p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
AND td.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id  := null;
v_ente_denominazione  := null;
v_anno_doc  := null;
v_num_doc  := null;
v_stato_sdi := null; -- SIAC-6565
v_desc_doc  := null;
v_importo_doc  := null;
v_beneficiario_multiplo_doc  := null;
v_data_emissione_doc  := null;
v_data_scadenza_doc  := null;
v_codice_bollo_doc  := null;
v_desc_codice_bollo_doc  := null;
v_collegato_cec_doc  := null;
v_cod_pcc_doc  := null;
v_desc_pcc_doc  := null;
v_cod_ufficio_doc  := null;
v_desc_ufficio_doc  := null;
v_cod_stato_doc  := null;
v_desc_stato_doc  := null;
v_cod_gruppo_doc  := null;
v_desc_gruppo_doc  := null;
v_cod_famiglia_doc  := null;
v_desc_famiglia_doc  := null;
v_cod_tipo_doc  := null;
v_desc_tipo_doc  := null;
v_sogg_id_doc  := null;
v_cod_sogg_doc  := null;
v_tipo_sogg_doc  := null;
v_stato_sogg_doc  := null;
v_rag_sociale_sogg_doc  := null;
v_p_iva_sogg_doc  := null;
v_cf_sogg_doc  := null;
v_cf_estero_sogg_doc  := null;
v_nome_sogg_doc  := null;
v_cognome_sogg_doc  := null;
v_bil_anno_ord := null;
v_anno_ord := null;
v_num_ord := null;
v_num_subord  := null;


v_doc_id  := null;
v_pcccod_id  := null;
v_pccuff_id  := null;

--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc := null;

v_ente_proprietario_id := rec_doc_id.ente_proprietario_id;
v_ente_denominazione := rec_doc_id.ente_denominazione;
v_anno_doc := rec_doc_id.doc_anno;
v_num_doc := rec_doc_id.doc_numero;
v_stato_sdi := rec_doc_id.stato_sdi; -- SIAC-6565
v_desc_doc := rec_doc_id.doc_desc;
v_importo_doc := rec_doc_id.doc_importo;
IF rec_doc_id.doc_beneficiariomult = 'FALSE' THEN
   v_beneficiario_multiplo_doc := 'F';
ELSE
   v_beneficiario_multiplo_doc := 'T';
END IF;
v_data_emissione_doc := rec_doc_id.doc_data_emissione;
v_data_scadenza_doc := rec_doc_id.doc_data_scadenza;
v_codice_bollo_doc := rec_doc_id.codbollo_code;
v_desc_codice_bollo_doc := rec_doc_id.codbollo_desc;
v_collegato_cec_doc := rec_doc_id.doc_collegato_cec;
v_cod_stato_doc := rec_doc_id.doc_stato_code;
v_desc_stato_doc := rec_doc_id.doc_stato_desc;
v_cod_gruppo_doc := rec_doc_id.doc_gruppo_tipo_code;
v_desc_gruppo_doc := rec_doc_id.doc_gruppo_tipo_desc;
v_cod_famiglia_doc := rec_doc_id.doc_fam_tipo_code;
v_desc_famiglia_doc := rec_doc_id.doc_fam_tipo_desc;
v_cod_tipo_doc := rec_doc_id.doc_tipo_code;
v_desc_tipo_doc := rec_doc_id.doc_tipo_desc;
v_sogg_id_doc := rec_doc_id.soggetto_id;
v_cod_sogg_doc := rec_doc_id.soggetto_code;
v_tipo_sogg_doc := rec_doc_id.soggetto_tipo_desc;
v_stato_sogg_doc := rec_doc_id.soggetto_stato_desc;
v_rag_sociale_sogg_doc := rec_doc_id.ragione_sociale;
v_p_iva_sogg_doc := rec_doc_id.partita_iva;
v_cf_sogg_doc := rec_doc_id.codice_fiscale;
v_cf_estero_sogg_doc := rec_doc_id.codice_fiscale_estero;
v_nome_sogg_doc := rec_doc_id.nome;
v_cognome_sogg_doc := rec_doc_id.cognome;

v_doc_id  := rec_doc_id.doc_id;
v_pcccod_id := rec_doc_id.pcccod_id;
v_pccuff_id := rec_doc_id.pccuff_id;

--nuova sezione coge 26-09-2016
IF rec_doc_id.doc_contabilizza_genpcc = 'FALSE' THEN
   v_doc_contabilizza_genpcc := 'F';
ELSE
   v_doc_contabilizza_genpcc := 'T';
END IF;

SELECT dpc.pcccod_code, dpc.pcccod_desc
INTO   v_cod_pcc_doc, v_desc_pcc_doc
FROM   siac.siac_d_pcc_codice dpc
WHERE  dpc.pcccod_id = v_pcccod_id
AND p_data BETWEEN dpc.validita_inizio AND COALESCE(dpc.validita_fine, p_data)
AND dpc.data_cancellazione IS NULL;

SELECT dpu.pccuff_code, dpu.pccuff_desc
INTO   v_cod_ufficio_doc, v_desc_ufficio_doc
FROM   siac.siac_d_pcc_ufficio dpu
WHERE  dpu.pccuff_id = v_pccuff_id
AND p_data BETWEEN dpu.validita_inizio AND COALESCE(dpu.validita_fine, p_data)
AND dpu.data_cancellazione IS NULL;

-- Ciclo per estrarre subdoc_id (subdocumenti)
FOR rec_subdoc_id IN
SELECT ts.subdoc_numero, ts.subdoc_desc, ts.subdoc_importo, ts.subdoc_nreg_iva, ts.subdoc_data_scadenza,
       ts.subdoc_convalida_manuale, ts.subdoc_importo_da_dedurre, ts.subdoc_splitreverse_importo,
       case when ts.subdoc_pagato_cec = FALSE then 'f' when ts.subdoc_pagato_cec = TRUE then 't' end subdoc_pagato_cec,
       ts.subdoc_data_pagamento_cec,
       taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daas.attoamm_stato_code, daas.attoamm_stato_desc,
       staa.attoal_causale, staa.attoal_altriallegati, staa.attoal_dati_sensibili,
       staa.attoal_data_scadenza, staa.attoal_note, staa.attoal_annotazioni, staa.attoal_pratica,
       staa.attoal_responsabile_amm, staa.attoal_responsabile_con, staa.attoal_titolario_anno,
       staa.attoal_titolario_numero, staa.attoal_versione_invio_firma,
       sdaas.attoal_stato_code, sdaas.attoal_stato_desc,
       ted.eldoc_anno, ted.eldoc_numero, ted.eldoc_data_trasmissione, ted.eldoc_tot_quoteentrate,
       ted.eldoc_tot_quotespese, ted.eldoc_tot_dapagare, ted.eldoc_tot_daincassare,
       deds.eldoc_stato_code, deds.eldoc_stato_desc, dnt.notetes_desc, dd.dist_code, dd.dist_desc, dc.contotes_desc,
       ts.subdoc_id, staa.attoal_id, taa.attoamm_id, taa.attoamm_tipo_id, ts.comm_tipo_id,
       staa.data_creazione data_ins_atto_allegato -- 22.05.2018 Sofia siac-6124
FROM siac.siac_t_subdoc ts
LEFT JOIN siac.siac_r_subdoc_atto_amm rsaa ON rsaa.subdoc_id = ts.subdoc_id
                                           AND p_data BETWEEN rsaa.validita_inizio AND COALESCE(rsaa.validita_fine, p_data)
                                           AND rsaa.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_amm taa ON taa.attoamm_id = rsaa.attoamm_id
                                   AND p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
                                   AND taa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_amm_stato raas ON raas.attoamm_id = taa.attoamm_id
                                          AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
                                          AND raas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_amm_stato daas ON daas.attoamm_stato_id = raas.attoamm_stato_id
                                          AND p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
                                          AND daas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_subdoc reds ON reds.subdoc_id = ts.subdoc_id
                                             AND p_data BETWEEN reds.validita_inizio AND COALESCE(reds.validita_fine, p_data)
                                             AND reds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_elenco_doc ted ON ted.eldoc_id = reds.eldoc_id
                                     AND p_data BETWEEN ted.validita_inizio AND COALESCE(ted.validita_fine, p_data)
                                     AND ted.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_elenco_doc raaed ON raaed.eldoc_id = ted.eldoc_id
                                                     AND p_data BETWEEN raaed.validita_inizio AND COALESCE(raaed.validita_fine, p_data)
                                                     AND raaed.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_allegato staa ON staa.attoal_id = raaed.attoal_id
                                         AND p_data BETWEEN staa.validita_inizio AND COALESCE(staa.validita_fine, p_data)
                                         AND staa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_stato sraas ON sraas.attoal_id = staa.attoal_id
                                                AND p_data BETWEEN sraas.validita_inizio AND COALESCE(sraas.validita_fine, p_data)
                                                AND sraas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_allegato_stato sdaas ON sdaas.attoal_stato_id = sraas.attoal_stato_id
                                                AND p_data BETWEEN sdaas.validita_inizio AND COALESCE(sdaas.validita_fine, p_data)
                                                AND sdaas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_stato  sreds ON sreds.eldoc_id = ted.eldoc_id
                                              AND p_data BETWEEN sreds.validita_inizio AND COALESCE(sreds.validita_fine, p_data)
                                              AND sreds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_elenco_doc_stato  deds ON deds.eldoc_stato_id = sreds.eldoc_stato_id
                                             AND p_data BETWEEN deds.validita_inizio AND COALESCE(deds.validita_fine, p_data)
                                             AND deds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_note_tesoriere  dnt ON dnt.notetes_id = ts.notetes_id
LEFT JOIN siac.siac_d_distinta  dd ON dd.dist_id = ts.dist_id
LEFT JOIN siac.siac_d_contotesoreria dc ON dc.contotes_id = ts.contotes_id
WHERE ts.doc_id = v_doc_id
AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND ts.data_cancellazione IS NULL

	LOOP

    v_num_subdoc  := null;
    v_desc_subdoc  := null;
    v_importo_subdoc  := null;
    v_num_reg_iva_subdoc  := null;
    v_data_scadenza_subdoc  := null;
    v_convalida_manuale_subdoc  := null;
    v_importo_da_dedurre_subdoc  := null;
    v_splitreverse_importo_subdoc  := null;
    v_pagato_cec_subdoc  := null;
    v_data_pagamento_cec_subdoc  := null;
    v_anno_atto_amministrativo  := null;
    v_num_atto_amministrativo  := null;
    v_oggetto_atto_amministrativo  := null;
    v_note_atto_amministrativo  := null;
    v_cod_tipo_atto_amministrativo  := null;
    v_desc_tipo_atto_amministrativo  := null;
    v_cod_stato_atto_amministrativo  := null;
    v_desc_stato_atto_amministrativo  := null;
    v_causale_atto_allegato  := null;
    v_altri_allegati_atto_allegato  := null;
    v_dati_sensibili_atto_allegato  := null;
    v_data_scadenza_atto_allegato  := null;
    v_note_atto_allegato  := null;
    v_annotazioni_atto_allegato  := null;
    v_pratica_atto_allegato  := null;
    v_resp_amm_atto_allegato  := null;
    v_resp_contabile_atto_allegato  := null;
    v_anno_titolario_atto_allegato  := null;
    v_num_titolario_atto_allegato  := null;
    v_vers_invio_firma_atto_allegato  := null;
    v_cod_stato_atto_allegato  := null;
    v_desc_stato_atto_allegato  := null;
    v_anno_elenco_doc  := null;
    v_num_elenco_doc  := null;
    v_data_trasmissione_elenco_doc  := null;
    v_tot_quote_entrate_elenco_doc  := null;
    v_tot_quote_spese_elenco_doc  := null;
    v_tot_da_pagare_elenco_doc  := null;
    v_tot_da_incassare_elenco_doc  := null;
    v_cod_stato_elenco_doc  := null;
    v_desc_stato_elenco_doc  := null;
    v_note_tesoriere_subdoc  := null;
    v_cod_distinta_subdoc  := null;
    v_desc_distinta_subdoc  := null;
    v_tipo_commissione_subdoc  := null;
    v_conto_tesoreria_subdoc  := null;

    v_sogg_id_atto_allegato  := null;
    v_cod_sogg_atto_allegato  := null;
    v_tipo_sogg_atto_allegato  := null;
    v_stato_sogg_atto_allegato  := null;
    v_rag_sociale_sogg_atto_allegato  := null;
    v_p_iva_sogg_atto_allegato  := null;
    v_cf_sogg_atto_allegato  := null;
    v_cf_estero_sogg_atto_allegato  := null;
    v_nome_sogg_atto_allegato  := null;
    v_cognome_sogg_atto_allegato  := null;

    v_cod_cdr_atto_amministrativo  := null;
    v_desc_cdr_atto_amministrativo  := null;
    v_cod_cdc_atto_amministrativo  := null;
    v_desc_cdc_atto_amministrativo  := null;
    v_cod_tipo_avviso  := null;
    v_desc_tipo_avviso  := null;

    v_cod_sogg_subdoc  := null;
    v_tipo_sogg_subdoc  := null;
    v_stato_sogg_subdoc  := null;
    v_rag_sociale_sogg_subdoc  := null;
    v_p_iva_sogg_subdoc  := null;
    v_cf_sogg_subdoc  := null;
    v_cf_estero_sogg_subdoc  := null;
    v_nome_sogg_subdoc  := null;
    v_cognome_sogg_subdoc  := null;

    v_sede_secondaria_subdoc := null;

    v_bil_anno := null;
    v_anno_accertamento := null;
    v_num_accertamento := null;
    v_cod_accertamento  := null;
    v_desc_accertamento  := null;
    v_cod_subaccertamento  := null;
    v_desc_subaccertamento  := null;

    v_quietanziante := null;
    v_data_nascita_quietanziante := null;
    v_luogo_nascita_quietanziante := null;
    v_stato_nascita_quietanziante := null;
    v_bic := null;
    v_contocorrente := null;
    v_intestazione_contocorrente := null;
    v_iban := null;
    v_mod_pag_id := null;
    v_note_mod_pag := null;
    v_data_scadenza_mod_pag := null;
    v_cod_tipo_accredito := null;
    v_desc_tipo_accredito := null;

    v_cod_sogg_mod_pag := null;
    v_tipo_sogg_mod_pag := null;
    v_stato_sogg_mod_pag := null;
    v_rag_sociale_sogg_mod_pag := null;
    v_p_iva_sogg_mod_pag := null;
    v_cf_sogg_mod_pag := null;
    v_cf_estero_sogg_mod_pag := null;
    v_nome_sogg_mod_pag := null;
    v_cognome_sogg_mod_pag := null;

    v_attoal_id  := null;
    v_subdoc_id  := null;
    v_attoamm_id  := null;
    v_classif_tipo_id := null;
    v_soggetto_id := null;
    v_soggetto_id_principale := null;
    v_movgest_ts_tipo_code := null;
    v_movgest_ts_code := null;
    v_soggetto_id_modpag_nocess := null;
    v_soggetto_id_modpag_cess := null;
    v_soggetto_id_modpag := null;
    v_soggrelmpag_id := null;
    v_attoamm_tipo_id := null;
    v_comm_tipo_id := null;


	-- 22.05.2018 Sofia siac-6124
    v_data_ins_atto_allegato:= null;
    v_data_completa_atto_allegato:= null;
    v_data_convalida_atto_allegato:= null;
    v_data_sosp_atto_allegato:=null;
    v_causale_sosp_atto_allegato:= null;
    v_data_riattiva_atto_allegato:= null;

    v_num_subdoc  := rec_subdoc_id.subdoc_numero;
    v_desc_subdoc  := rec_subdoc_id.subdoc_desc;
    v_importo_subdoc  := rec_subdoc_id.subdoc_importo;
    v_num_reg_iva_subdoc  := rec_subdoc_id.subdoc_nreg_iva;
    v_data_scadenza_subdoc  := rec_subdoc_id.subdoc_data_scadenza;
    v_convalida_manuale_subdoc  := rec_subdoc_id.subdoc_convalida_manuale;
    v_importo_da_dedurre_subdoc  := rec_subdoc_id.subdoc_importo_da_dedurre;
    v_splitreverse_importo_subdoc  := rec_subdoc_id.subdoc_splitreverse_importo;
    v_pagato_cec_subdoc  := rec_subdoc_id.subdoc_pagato_cec;
    v_data_pagamento_cec_subdoc  := rec_subdoc_id.subdoc_data_pagamento_cec;
    v_anno_atto_amministrativo  := rec_subdoc_id.attoamm_anno;
    v_num_atto_amministrativo  := rec_subdoc_id.attoamm_numero;
    v_oggetto_atto_amministrativo  := rec_subdoc_id.attoamm_oggetto;
    v_note_atto_amministrativo  := rec_subdoc_id.attoamm_note;
    v_cod_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_code;
    v_desc_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_desc;
    v_causale_atto_allegato  := rec_subdoc_id.attoal_causale;
    v_altri_allegati_atto_allegato  := rec_subdoc_id.attoal_altriallegati;
    v_dati_sensibili_atto_allegato  := rec_subdoc_id.attoal_dati_sensibili;
    v_data_scadenza_atto_allegato  := rec_subdoc_id.attoal_data_scadenza;
    v_note_atto_allegato  := rec_subdoc_id.attoal_note;
    v_annotazioni_atto_allegato  := rec_subdoc_id.attoal_annotazioni;
    v_pratica_atto_allegato  := rec_subdoc_id.attoal_pratica;
    v_resp_amm_atto_allegato  := rec_subdoc_id.attoal_responsabile_amm;
    v_resp_contabile_atto_allegato  := rec_subdoc_id.attoal_responsabile_con;
    v_anno_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_anno;
    v_num_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_numero;
    v_vers_invio_firma_atto_allegato  := rec_subdoc_id.attoal_versione_invio_firma;
    v_cod_stato_atto_allegato  := rec_subdoc_id.attoal_stato_code;
    v_desc_stato_atto_allegato  := rec_subdoc_id.attoal_stato_desc;
    v_anno_elenco_doc  := rec_subdoc_id.eldoc_anno;
    v_num_elenco_doc  := rec_subdoc_id.eldoc_numero;
    v_data_trasmissione_elenco_doc  := rec_subdoc_id.eldoc_data_trasmissione;
    v_tot_quote_entrate_elenco_doc  := rec_subdoc_id.eldoc_tot_quoteentrate;
    v_tot_quote_spese_elenco_doc  := rec_subdoc_id.eldoc_tot_quotespese;
    v_tot_da_pagare_elenco_doc  := rec_subdoc_id.eldoc_tot_dapagare;
    v_tot_da_incassare_elenco_doc  := rec_subdoc_id.eldoc_tot_daincassare;
    v_cod_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_code;
    v_desc_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_desc;
    v_note_tesoriere_subdoc  := rec_subdoc_id.notetes_desc;
    v_cod_distinta_subdoc  := rec_subdoc_id.dist_code;
    v_desc_distinta_subdoc  := rec_subdoc_id.dist_desc;
    v_conto_tesoreria_subdoc  := rec_subdoc_id.contotes_desc;

    v_attoal_id  := rec_subdoc_id.attoal_id;
    v_subdoc_id  := rec_subdoc_id.subdoc_id;
    v_attoamm_id  := rec_subdoc_id.attoamm_id;
    v_attoamm_tipo_id  := rec_subdoc_id.attoamm_tipo_id;
    v_comm_tipo_id  := rec_subdoc_id.comm_tipo_id;

    -- 22.05.2018 Sofia siac-6124
    v_data_ins_atto_allegato:=rec_subdoc_id.data_ins_atto_allegato;

    -- Sezione per estrarre il tipo di atto amministrativo
    SELECT daat.attoamm_tipo_code, daat.attoamm_tipo_desc
    INTO   v_cod_tipo_atto_amministrativo, v_desc_tipo_atto_amministrativo
    FROM  siac.siac_d_atto_amm_tipo daat
    WHERE daat.attoamm_tipo_id = v_attoamm_tipo_id
    AND p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data)
    AND daat.data_cancellazione IS NULL;
    -- Sezione per estrarre il tipo commissione
    SELECT dct.comm_tipo_desc
    INTO  v_tipo_commissione_subdoc
    FROM siac.siac_d_commissione_tipo dct
    WHERE dct.comm_tipo_id = v_comm_tipo_id
    AND p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)
    AND dct.data_cancellazione IS NULL;

   -- esito:= '    Inizio step per i soggetti legati all''atto allegato @@@@@@@@@@@@@@@@@@ - '||clock_timestamp();
   -- return next;
    --  Sezione per i soggetti legati all'atto allegato
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, ts.soggetto_id,
           raas.attoal_sog_data_sosp, raas.attoal_sog_causale_sosp, raas.attoal_sog_data_riatt  -- 22.05.2018 Sofia siac-6124
    INTO   v_cod_sogg_atto_allegato, v_tipo_sogg_atto_allegato, v_stato_sogg_atto_allegato, v_rag_sociale_sogg_atto_allegato,
           v_p_iva_sogg_atto_allegato, v_cf_sogg_atto_allegato, v_cf_estero_sogg_atto_allegato,
           v_nome_sogg_atto_allegato, v_cognome_sogg_atto_allegato, v_sogg_id_atto_allegato,
           v_data_sosp_atto_allegato,v_causale_sosp_atto_allegato, v_data_riattiva_atto_allegato -- 22.05.2018 Sofia siac-6124
    FROM siac.siac_r_atto_allegato_sog raas
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = raas.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
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
    WHERE raas.attoal_id = v_attoal_id
    AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
    AND raas.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

   -- esito:= '    Fine step per i soggetti legati all''atto allegato v_data_sosp_atto_allegato='||coalesce(to_char(v_data_sosp_atto_allegato,'dd/mm/yyyy'),'****' )||' - '||clock_timestamp();
   -- return next;

    esito:= '    Inizio step data completamento, convalida atto_allegato - '||clock_timestamp();
    return next;
	-- 22.05.2018 Sofia siac-6124
    v_data_completa_atto_allegato:=fnc_siac_attoal_getDataStato(v_attoal_id,'C');
    v_data_convalida_atto_allegato:=fnc_siac_attoal_getDataStato(v_attoal_id,'CV');
    esito:= '    Fine step data completamento, convalida atto_allegato - '||clock_timestamp();
    return next;

    -- Sezione per i classificatori legati ai subdocumenti
    esito:= '    Inizio step classificatori per subdocumenti - '||clock_timestamp();
    return next;
    FOR rec_classif_id IN
    SELECT tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_subdoc_class rsc, siac.siac_t_class tc
    WHERE tc.classif_id = rsc.classif_id
    AND   rsc.subdoc_id = v_subdoc_id
    AND   rsc.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN rsc.validita_inizio AND COALESCE(rsc.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
      v_classif_code := rec_classif_id.classif_code;
      v_classif_desc := rec_classif_id.classif_desc;

      v_classif_tipo_code := null;

      SELECT dct.classif_tipo_code
      INTO   v_classif_tipo_code
      FROM   siac.siac_d_class_tipo dct
      WHERE  dct.classif_tipo_id = v_classif_tipo_id
      AND    dct.data_cancellazione IS NULL
      AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'TIPO_AVVISO' THEN
         v_cod_tipo_avviso  := v_classif_code;
         v_desc_tipo_avviso :=  v_classif_desc;
      END IF;

    END LOOP;
    esito:= '    Fine step classificatori per subdocumenti - '||clock_timestamp();
    return next;

    -- Sezione per i classificatori legati agli atti amministrativi
    esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;
    FOR rec_classif_id_attr IN
    SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_atto_amm_class raac, siac.siac_t_class tc
    WHERE tc.classif_id = raac.classif_id
    AND   raac.attoamm_id = v_attoamm_id
    AND   raac.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_conta_ciclo_classif :=0;
      v_classif_id_padre := null;

      -- Loop per RISALIRE la gerarchia di un dato classificatore
      LOOP

          v_classif_code := null;
          v_classif_desc := null;
          v_classif_id_part := null;
          v_classif_tipo_code := null;

          IF v_conta_ciclo_classif = 0 THEN
             v_classif_id_part := rec_classif_id_attr.classif_id;
          ELSE
             v_classif_id_part := v_classif_id_padre;
          END IF;

          SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code
          INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code
          FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
          WHERE rcft.classif_id = tc.classif_id
          AND   dct.classif_tipo_id = tc.classif_tipo_id
          AND   tc.classif_id = v_classif_id_part
          AND   rcft.data_cancellazione IS NULL
          AND   tc.data_cancellazione IS NULL
          AND   dct.data_cancellazione IS NULL
          AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
          AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
          AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

          IF v_classif_tipo_code = 'CDR' THEN
             v_cod_cdr_atto_amministrativo := v_classif_code;
             v_desc_cdr_atto_amministrativo := v_classif_desc;
          ELSIF v_classif_tipo_code = 'CDC' THEN
             v_cod_cdc_atto_amministrativo := v_classif_code;
             v_desc_cdc_atto_amministrativo := v_classif_desc;
          END IF;

          v_conta_ciclo_classif := v_conta_ciclo_classif +1;
          EXIT WHEN v_classif_id_padre IS NULL;

      END LOOP;
    END LOOP;
    esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;

    -- Sezione pe gli attributi
    v_rilevante_iva := null;
    v_ordinativo_singolo := null;
    v_ordinativo_manuale := null;
    v_esproprio := null;
    v_note := null;
    v_avviso := null;

    v_flag_attributo := null;

--nuova sezione coge 26-09-2016
    v_registro_repertorio := null;
    v_anno_repertorio := null;
    v_num_repertorio := null;
    v_data_repertorio := null;

FOR rec_doc_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_doc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat, siac_t_subdoc z
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    dat.data_cancellazione IS NULL
    and z.doc_id=rsa.doc_id
    and z.subdoc_id = v_subdoc_id
    AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
    AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
    AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
    and ta.attr_code in ( 'registro_repertorio','anno_repertorio','num_repertorio',
    'data_repertorio' ,'dataRicezionePortale','arrotondamento')

LOOP

      IF rec_doc_attr.attr_tipo_code = 'X' THEN
         v_flag_attributo := rec_doc_attr.testo::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'N' THEN
         v_flag_attributo := rec_doc_attr.numerico::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'P' THEN
         v_flag_attributo := rec_doc_attr.percentuale::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'B' THEN
         v_flag_attributo := rec_doc_attr.true_false::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'T' THEN
         v_flag_attributo := rec_doc_attr.tabella_id::varchar;
      END IF;

      --nuova sezione coge 26-09-2016
      IF rec_doc_attr.attr_code = 'registro_repertorio' THEN
         v_registro_repertorio := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'anno_repertorio' THEN
         v_anno_repertorio := v_flag_attributo;
	  ELSIF rec_doc_attr.attr_code = 'num_repertorio' THEN
         v_num_repertorio := v_flag_attributo;
	  ELSIF rec_doc_attr.attr_code = 'data_repertorio' THEN
         v_data_repertorio := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'dataRicezionePortale' THEN
         v_data_ricezione_portale := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'arrotondamento' THEN
         v_arrotondamento := v_flag_attributo;
      END IF;

    END LOOP;


    FOR rec_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_subdoc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.subdoc_id = v_subdoc_id
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

      IF rec_attr.attr_code = 'flagRilevanteIVA' THEN
         v_rilevante_iva := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoManuale' THEN
         v_ordinativo_manuale := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoSingolo' THEN
         v_ordinativo_singolo := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagEsproprio' THEN
         v_esproprio := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'Note' THEN
         v_note := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagAvviso' THEN
         v_avviso := v_flag_attributo;
      END IF;

    END LOOP;

    --  Sezione per i soggetti legati al subdoc
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, rss.soggetto_id
    INTO v_cod_sogg_subdoc, v_tipo_sogg_subdoc, v_stato_sogg_subdoc, v_rag_sociale_sogg_subdoc,
         v_p_iva_sogg_subdoc, v_cf_sogg_subdoc, v_cf_estero_sogg_subdoc,
         v_nome_sogg_subdoc, v_cognome_sogg_subdoc, v_soggetto_id
    FROM siac.siac_r_subdoc_sog rss
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = rss.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE rss.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
    AND rss.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    -- Sezione per valorizzare la sede secondaria
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
        v_sede_secondaria_subdoc := 'S';
    END IF;

    -- Sezione per gli accertamenti
    SELECT tp.anno, tm.movgest_anno, tm.movgest_numero, dmtt.movgest_ts_tipo_code,
           tmt.movgest_ts_code, tmt.movgest_ts_desc, tm.movgest_desc
    INTO v_bil_anno, v_anno_accertamento, v_num_accertamento, v_movgest_ts_tipo_code,
         v_movgest_ts_code, v_desc_subaccertamento, v_desc_accertamento
    FROM siac.siac_r_subdoc_movgest_ts rsmt
    INNER JOIN siac.siac_t_movgest_ts tmt ON tmt.movgest_ts_id = rsmt.movgest_ts_id
    INNER JOIN siac.siac_t_movgest tm ON tm.movgest_id = tmt.movgest_id
    LEFT JOIN siac.siac_t_bil tb ON tb.bil_id = tm.bil_id
                                 AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
                                 AND tb.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_periodo tp ON  tp.periodo_id = tb.periodo_id
                                     AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
                                     AND tp.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_movgest_tipo dmt ON dmt.movgest_tipo_id = tm.movgest_tipo_id
    INNER JOIN siac.siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
    WHERE rsmt.subdoc_id = v_subdoc_id
    AND dmt.movgest_tipo_code = 'A'
    AND p_data BETWEEN rsmt.validita_inizio AND COALESCE(rsmt.validita_fine, p_data)
    AND rsmt.data_cancellazione IS NULL
    AND p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
    AND tmt.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL
    AND p_data BETWEEN dmt.validita_inizio AND COALESCE(dmt.validita_fine, p_data)
    AND dmt.data_cancellazione IS NULL
    AND p_data BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, p_data)
    AND dmtt.data_cancellazione IS NULL;

    IF v_movgest_ts_tipo_code = 'T' THEN
       v_cod_accertamento := v_movgest_ts_code;
       v_desc_subaccertamento := NULL;
    ELSIF v_movgest_ts_tipo_code = 'S' THEN
          v_cod_subaccertamento := v_movgest_ts_code;
          v_desc_accertamento := NULL;
    END IF;

    -- Sezione per la modalita' di pagamento
    SELECT tm.quietanziante, tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo, tm.quietanziante_nascita_stato,
           tm.bic, tm.contocorrente, tm.contocorrente_intestazione, tm.iban, tm.note, tm.data_scadenza,
           dat.accredito_tipo_code, dat.accredito_tipo_desc, tm.soggetto_id, rsm.soggrelmpag_id, tm.modpag_id
    INTO   v_quietanziante, v_data_nascita_quietanziante, v_luogo_nascita_quietanziante, v_stato_nascita_quietanziante,
           v_bic, v_contocorrente, v_intestazione_contocorrente, v_iban, v_note_mod_pag, v_data_scadenza_mod_pag,
           v_cod_tipo_accredito, v_desc_tipo_accredito, v_soggetto_id_modpag_nocess, v_soggrelmpag_id, v_mod_pag_id
    FROM siac.siac_r_subdoc_modpag rsm
    INNER JOIN siac.siac_t_modpag tm ON tm.modpag_id = rsm.modpag_id
    LEFT JOIN siac.siac_d_accredito_tipo dat ON dat.accredito_tipo_id = tm.accredito_tipo_id
                                             AND p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
                                             AND dat.data_cancellazione IS NULL
    WHERE rsm.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
    AND rsm.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL;

    IF v_soggrelmpag_id IS NULL THEN
       v_soggetto_id_modpag := v_soggetto_id_modpag_nocess;
    ELSE
       SELECT rsr.soggetto_id_a
       INTO  v_soggetto_id_modpag_cess
       FROM  siac.siac_r_soggrel_modpag rsm, siac.siac_r_soggetto_relaz rsr
       WHERE rsm.soggrelmpag_id = v_soggrelmpag_id
       AND   rsm.soggetto_relaz_id = rsr.soggetto_relaz_id
       AND   p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
       AND   rsm.data_cancellazione IS NULL
       AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
       AND   rsr.data_cancellazione IS NULL;

       v_soggetto_id_modpag := v_soggetto_id_modpag_cess;
    END IF;

    --  Sezione per i soggetti legati alla modalita' pagamento
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome
    INTO   v_cod_sogg_mod_pag, v_tipo_sogg_mod_pag, v_stato_sogg_mod_pag, v_rag_sociale_sogg_mod_pag,
           v_p_iva_sogg_mod_pag, v_cf_sogg_mod_pag, v_cf_estero_sogg_mod_pag,
           v_nome_sogg_mod_pag, v_cognome_sogg_mod_pag
    FROM siac.siac_t_soggetto ts
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE ts.soggetto_id = v_soggetto_id_modpag
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    SELECT sto.ord_anno, sto.ord_numero, tt.ord_ts_code, tp.anno
    INTO  v_anno_ord, v_num_ord, v_num_subord, v_bil_anno_ord
    FROM  siac_r_subdoc_ordinativo_ts rsot, siac_t_ordinativo_ts tt, siac_t_ordinativo sto,
          siac_r_ordinativo_stato ros, siac_d_ordinativo_stato dos,
          siac.siac_t_bil tb, siac.siac_t_periodo tp
    WHERE tt.ord_ts_id = rsot.ord_ts_id
    AND   sto.ord_id = tt.ord_id
    AND   ros.ord_id = sto.ord_id
    AND   ros.ord_stato_id = dos.ord_stato_id
    AND   sto.bil_id = tb.bil_id
    AND   tp.periodo_id = tb.periodo_id
    AND   rsot.subdoc_id = v_subdoc_id
    AND   dos.ord_stato_code <> 'A'
    AND   rsot.data_cancellazione IS NULL
    AND   tt.data_cancellazione IS NULL
    AND   sto.data_cancellazione IS NULL
    AND   ros.data_cancellazione IS NULL
    AND   dos.data_cancellazione IS NULL
    AND   tb.data_cancellazione IS NULL
    AND   tp.data_cancellazione IS NULL
    AND   p_data between rsot.validita_inizio and COALESCE(rsot.validita_fine,p_data)
    AND   p_data between tt.validita_inizio and COALESCE(tt.validita_fine,p_data)
    AND   p_data between sto.validita_inizio and COALESCE(sto.validita_fine,p_data)
    AND   p_data between ros.validita_inizio and COALESCE(ros.validita_fine,p_data)
    AND   p_data between dos.validita_inizio and COALESCE(dos.validita_fine,p_data)
    AND   p_data between tb.validita_inizio and COALESCE(tb.validita_fine,p_data)
    AND   p_data between tp.validita_inizio and COALESCE(tp.validita_fine,p_data);



      INSERT INTO siac.siac_dwh_documento_entrata
      ( ente_proprietario_id,
        ente_denominazione,
        anno_atto_amministrativo,
        num_atto_amministrativo,
        oggetto_atto_amministrativo,
        cod_tipo_atto_amministrativo,
        desc_tipo_atto_amministrativo,
        cod_cdr_atto_amministrativo,
        desc_cdr_atto_amministrativo,
        cod_cdc_atto_amministrativo,
        desc_cdc_atto_amministrativo,
        note_atto_amministrativo,
        cod_stato_atto_amministrativo,
        desc_stato_atto_amministrativo,
        causale_atto_allegato,
        altri_allegati_atto_allegato,
        dati_sensibili_atto_allegato,
        data_scadenza_atto_allegato,
        note_atto_allegato,
        annotazioni_atto_allegato,
        pratica_atto_allegato,
        resp_amm_atto_allegato,
        resp_contabile_atto_allegato,
        anno_titolario_atto_allegato,
        num_titolario_atto_allegato,
        vers_invio_firma_atto_allegato,
        cod_stato_atto_allegato,
        desc_stato_atto_allegato,
        sogg_id_atto_allegato,
        cod_sogg_atto_allegato,
        tipo_sogg_atto_allegato,
        stato_sogg_atto_allegato,
        rag_sociale_sogg_atto_allegato,
        p_iva_sogg_atto_allegato,
        cf_sogg_atto_allegato,
        cf_estero_sogg_atto_allegato,
        nome_sogg_atto_allegato,
        cognome_sogg_atto_allegato,
        anno_doc,
        num_doc,
        desc_doc,
        importo_doc,
        beneficiario_multiplo_doc,
        data_emissione_doc,
        data_scadenza_doc,
        codice_bollo_doc,
        desc_codice_bollo_doc,
        collegato_cec_doc,
        cod_pcc_doc,
        desc_pcc_doc,
        cod_ufficio_doc,
        desc_ufficio_doc,
        cod_stato_doc,
        desc_stato_doc,
        anno_elenco_doc,
        num_elenco_doc,
        data_trasmissione_elenco_doc,
        tot_quote_entrate_elenco_doc,
        tot_quote_spese_elenco_doc,
        tot_da_pagare_elenco_doc,
        tot_da_incassare_elenco_doc,
        cod_stato_elenco_doc,
        desc_stato_elenco_doc,
        cod_gruppo_doc,
        desc_gruppo_doc,
        cod_famiglia_doc,
        desc_famiglia_doc,
        cod_tipo_doc,
        desc_tipo_doc,
        sogg_id_doc,
        cod_sogg_doc,
        tipo_sogg_doc,
        stato_sogg_doc,
        rag_sociale_sogg_doc,
        p_iva_sogg_doc,
        cf_sogg_doc,
        cf_estero_sogg_doc,
        nome_sogg_doc,
        cognome_sogg_doc,
        num_subdoc,
        desc_subdoc,
        importo_subdoc,
        num_reg_iva_subdoc,
        data_scadenza_subdoc,
        convalida_manuale_subdoc,
        importo_da_dedurre_subdoc,
        splitreverse_importo_subdoc,
        pagato_cec_subdoc,
        data_pagamento_cec_subdoc,
        note_tesoriere_subdoc,
        cod_distinta_subdoc,
        desc_distinta_subdoc,
        tipo_commissione_subdoc,
        conto_tesoreria_subdoc,
        rilevante_iva,
        ordinativo_singolo,
        ordinativo_manuale,
        esproprio,
        note,
        avviso,
        cod_tipo_avviso,
        desc_tipo_avviso,
        sogg_id_subdoc,
        cod_sogg_subdoc,
        tipo_sogg_subdoc,
        stato_sogg_subdoc,
        rag_sociale_sogg_subdoc,
        p_iva_sogg_subdoc,
        cf_sogg_subdoc,
        cf_estero_sogg_subdoc,
        nome_sogg_subdoc,
        cognome_sogg_subdoc,
        sede_secondaria_subdoc,
        bil_anno,
        anno_accertamento,
        num_accertamento,
        cod_accertamento,
        desc_accertamento,
        cod_subaccertamento,
        desc_subaccertamento,
        cod_tipo_accredito,
        desc_tipo_accredito,
        mod_pag_id,
        quietanziante,
        data_nascita_quietanziante,
        luogo_nascita_quietanziante,
        stato_nascita_quietanziante,
        bic,
        contocorrente,
        intestazione_contocorrente,
        iban,
        note_mod_pag,
        data_scadenza_mod_pag,
        sogg_id_mod_pag,
        cod_sogg_mod_pag,
        tipo_sogg_mod_pag,
        stato_sogg_mod_pag,
        rag_sociale_sogg_mod_pag,
        p_iva_sogg_mod_pag,
        cf_sogg_mod_pag,
        cf_estero_sogg_mod_pag,
        nome_sogg_mod_pag,
        cognome_sogg_mod_pag,
        bil_anno_ord,
        anno_ord,
        num_ord,
        num_subord,
        --nuova sezione coge 26-09-2016
        registro_repertorio,
		anno_repertorio,
		num_repertorio,
		data_repertorio,
        data_ricezione_portale,
        arrotondamento,
		doc_contabilizza_genpcc,
        doc_id, -- SIAC-5573 ,
        -- 22.05.2018 Sofia siac-6124
        data_ins_atto_allegato,
        data_completa_atto_allegato,
        data_convalida_atto_allegato,
        data_sosp_atto_allegato,
        causale_sosp_atto_allegato,
        data_riattiva_atto_allegato,
        stato_sdi -- SIAC-6565 07.05.2019 SofiaElisa
      )
      VALUES (v_ente_proprietario_id,
              v_ente_denominazione,
              v_anno_atto_amministrativo,
              v_num_atto_amministrativo,
              v_oggetto_atto_amministrativo,
              v_cod_tipo_atto_amministrativo,
              v_desc_tipo_atto_amministrativo,
              v_cod_cdr_atto_amministrativo,
              v_desc_cdr_atto_amministrativo,
              v_cod_cdc_atto_amministrativo,
              v_desc_cdc_atto_amministrativo,
              v_note_atto_amministrativo,
              v_cod_stato_atto_amministrativo,
              v_desc_stato_atto_amministrativo,
              v_causale_atto_allegato,
              v_altri_allegati_atto_allegato,
              v_dati_sensibili_atto_allegato,
              v_data_scadenza_atto_allegato,
              v_note_atto_allegato,
              v_annotazioni_atto_allegato,
              v_pratica_atto_allegato,
              v_resp_amm_atto_allegato,
              v_resp_contabile_atto_allegato,
              v_anno_titolario_atto_allegato,
              v_num_titolario_atto_allegato,
              v_vers_invio_firma_atto_allegato,
              v_cod_stato_atto_allegato,
              v_desc_stato_atto_allegato,
              v_sogg_id_atto_allegato,
              v_cod_sogg_atto_allegato,
              v_tipo_sogg_atto_allegato,
              v_stato_sogg_atto_allegato,
              v_rag_sociale_sogg_atto_allegato,
              v_p_iva_sogg_atto_allegato,
              v_cf_sogg_atto_allegato,
              v_cf_estero_sogg_atto_allegato,
              v_nome_sogg_atto_allegato,
              v_cognome_sogg_atto_allegato,
              v_anno_doc,
              v_num_doc,
              v_desc_doc,
              v_importo_doc,
              v_beneficiario_multiplo_doc,
              v_data_emissione_doc,
              v_data_scadenza_doc,
              v_codice_bollo_doc,
              v_desc_codice_bollo_doc,
              v_collegato_cec_doc,
              v_cod_pcc_doc,
              v_desc_pcc_doc,
              v_cod_ufficio_doc,
              v_desc_ufficio_doc,
              v_cod_stato_doc,
              v_desc_stato_doc,
              v_anno_elenco_doc,
              v_num_elenco_doc,
              v_data_trasmissione_elenco_doc,
              v_tot_quote_entrate_elenco_doc,
              v_tot_quote_spese_elenco_doc,
              v_tot_da_pagare_elenco_doc,
              v_tot_da_incassare_elenco_doc,
              v_cod_stato_elenco_doc,
              v_desc_stato_elenco_doc,
              v_cod_gruppo_doc,
              v_desc_gruppo_doc,
              v_cod_famiglia_doc,
              v_desc_famiglia_doc,
              v_cod_tipo_doc,
              v_desc_tipo_doc,
              v_sogg_id_doc,
              v_cod_sogg_doc,
              v_tipo_sogg_doc,
              v_stato_sogg_doc,
              v_rag_sociale_sogg_doc,
              v_p_iva_sogg_doc,
              v_cf_sogg_doc,
              v_cf_estero_sogg_doc,
              v_nome_sogg_doc,
              v_cognome_sogg_doc,
              v_num_subdoc,
              v_desc_subdoc,
              v_importo_subdoc,
              v_num_reg_iva_subdoc,
              v_data_scadenza_subdoc,
              v_convalida_manuale_subdoc,
              v_importo_da_dedurre_subdoc,
              v_splitreverse_importo_subdoc,
              v_pagato_cec_subdoc,
              v_data_pagamento_cec_subdoc,
              v_note_tesoriere_subdoc,
              v_cod_distinta_subdoc,
              v_desc_distinta_subdoc,
              v_tipo_commissione_subdoc,
              v_conto_tesoreria_subdoc,
              v_rilevante_iva,
              v_ordinativo_singolo,
              v_ordinativo_manuale,
              v_esproprio,
              v_note,
              v_avviso,
              v_cod_tipo_avviso,
              v_desc_tipo_avviso,
              v_soggetto_id,
              v_cod_sogg_subdoc,
              v_tipo_sogg_subdoc,
              v_stato_sogg_subdoc,
              v_rag_sociale_sogg_subdoc,
              v_p_iva_sogg_subdoc,
              v_cf_sogg_subdoc,
              v_cf_estero_sogg_subdoc,
              v_nome_sogg_subdoc,
              v_cognome_sogg_subdoc,
              v_sede_secondaria_subdoc,
              v_bil_anno,
              v_anno_accertamento,
              v_num_accertamento,
              v_cod_accertamento,
              v_desc_accertamento,
              v_cod_subaccertamento,
              v_desc_subaccertamento,
              v_cod_tipo_accredito,
              v_desc_tipo_accredito,
              v_mod_pag_id,
              v_quietanziante,
              v_data_nascita_quietanziante,
              v_luogo_nascita_quietanziante,
              v_stato_nascita_quietanziante,
              v_bic,
              v_contocorrente,
              v_intestazione_contocorrente,
              v_iban,
              v_note_mod_pag,
              v_data_scadenza_mod_pag,
              v_soggetto_id_modpag,
              v_cod_sogg_mod_pag,
              v_tipo_sogg_mod_pag,
              v_stato_sogg_mod_pag,
              v_rag_sociale_sogg_mod_pag,
              v_p_iva_sogg_mod_pag,
              v_cf_sogg_mod_pag,
              v_cf_estero_sogg_mod_pag,
              v_nome_sogg_mod_pag,
              v_cognome_sogg_mod_pag,
              v_bil_anno_ord,
              v_anno_ord,
              v_num_ord,
              v_num_subord,
              --nuova sezione coge 26-09-2016
              v_registro_repertorio,
			  v_anno_repertorio,
			  v_num_repertorio,
			  v_data_repertorio,
              v_data_ricezione_portale,
              v_arrotondamento::numeric,
			  v_doc_contabilizza_genpcc,
              v_doc_id, -- SIAC-5573  ,
              -- 22.05.2018 Sofia siac-6124
	          v_data_ins_atto_allegato,
	          v_data_completa_atto_allegato,
		      v_data_convalida_atto_allegato,
	  	      v_data_sosp_atto_allegato,
        	  v_causale_sosp_atto_allegato,
	          v_data_riattiva_atto_allegato,
              v_stato_sdi -- SIAC-6565 07.05.2019 SofiaElisa
             );

	END LOOP;

END LOOP;
esito:= 'Fine funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;


update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp() - fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;