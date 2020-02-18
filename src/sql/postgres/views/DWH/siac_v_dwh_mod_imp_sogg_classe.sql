/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_imp_sogg_classe (
    ente_proprietario_id,
    bil_anno,
    anno_impegno,
    num_impegno,
    cod_movgest_ts,
    desc_movgest_ts,
    tipo_movgest_ts,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_old,
    desc_old,
    cf_old,
    cf_estero_old,
    partita_iva_old,
    cod_tipo_old,
    desc_tipo_old,
    cod_new,
    desc_new,
    cf_new,
    cf_estero_new,
    partita_iva_new,
    cod_tipo_new,
    desc_tipo_new,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    desc_stato_modifica,
    tipo_modifica,
    data_creazione -- 30.08.2018 Sofia jira-6292
  )
AS
(
SELECT siac_v_dwh_mod_impegno_sogg.ente_proprietario_id,
       siac_v_dwh_mod_impegno_sogg.bil_anno_sogg AS bil_anno,
       siac_v_dwh_mod_impegno_sogg.anno_impegno_sogg AS anno_impegno,
       siac_v_dwh_mod_impegno_sogg.num_impegno_sogg AS num_impegno,
       siac_v_dwh_mod_impegno_sogg.cod_movgest_ts_sogg AS cod_movgest_ts,
       siac_v_dwh_mod_impegno_sogg.desc_movgest_ts_sogg AS desc_movgest_ts,
       siac_v_dwh_mod_impegno_sogg.tipo_movgest_ts_sogg AS tipo_movgest_ts,
       siac_v_dwh_mod_impegno_sogg.numero_modifica,
       siac_v_dwh_mod_impegno_sogg.desc_modifica,
       siac_v_dwh_mod_impegno_sogg.stato_modifica,
       siac_v_dwh_mod_impegno_sogg.cod_tipo_modifica,
       siac_v_dwh_mod_impegno_sogg.desc_tipo_modifica,
       siac_v_dwh_mod_impegno_sogg.cod_soggeto_old AS cod_old,
       siac_v_dwh_mod_impegno_sogg.desc_soggetto_old AS desc_old,
       siac_v_dwh_mod_impegno_sogg.cf_old,
       siac_v_dwh_mod_impegno_sogg.cf_estero_old,
       siac_v_dwh_mod_impegno_sogg.partita_iva_old,
       NULL::character varying AS cod_tipo_old,
       NULL::character varying AS desc_tipo_old,
       siac_v_dwh_mod_impegno_sogg.cod_soggeto_new AS cod_new,
       siac_v_dwh_mod_impegno_sogg.desc_soggetto_new AS desc_new,
       siac_v_dwh_mod_impegno_sogg.cf_new,
       siac_v_dwh_mod_impegno_sogg.cf_estero_new,
       siac_v_dwh_mod_impegno_sogg.partita_iva_new,
       NULL::character varying AS cod_tipo_new,
       NULL::character varying AS desc_tipo_new,
       siac_v_dwh_mod_impegno_sogg.anno_atto_amministrativo,
       siac_v_dwh_mod_impegno_sogg.num_atto_amministrativo,
       siac_v_dwh_mod_impegno_sogg.cod_tipo_atto_amministrativo,
       siac_v_dwh_mod_impegno_sogg.cod_sac,
       siac_v_dwh_mod_impegno_sogg.desc_sac,
       siac_v_dwh_mod_impegno_sogg.tipo_sac,
       siac_v_dwh_mod_impegno_sogg.desc_stato_modifica,
       siac_v_dwh_mod_impegno_sogg.tipo_modifica,
       siac_v_dwh_mod_impegno_sogg.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_v_dwh_mod_impegno_sogg
WHERE siac_v_dwh_mod_impegno_sogg.tipo_modifica = 'SS'::text
UNION
SELECT siac_v_dwh_mod_impegno_classe.ente_proprietario_id,
       siac_v_dwh_mod_impegno_classe.bil_anno_classe AS bil_anno,
       siac_v_dwh_mod_impegno_classe.anno_impegno_classe AS anno_impegno,
       siac_v_dwh_mod_impegno_classe.num_impegno_classe AS num_impegno,
       siac_v_dwh_mod_impegno_classe.cod_movgest_ts_classe  AS cod_movgest_ts,
       siac_v_dwh_mod_impegno_classe.desc_movgest_ts_classe AS desc_movgest_ts,
       siac_v_dwh_mod_impegno_classe.tipo_movgest_ts_classe AS tipo_movgest_ts,
       siac_v_dwh_mod_impegno_classe.numero_modifica,
       siac_v_dwh_mod_impegno_classe.desc_modifica,
       siac_v_dwh_mod_impegno_classe.stato_modifica,
       siac_v_dwh_mod_impegno_classe.cod_tipo_modifica,
       siac_v_dwh_mod_impegno_classe.desc_tipo_modifica,
       siac_v_dwh_mod_impegno_classe.cod_soggetto_classe_old AS cod_old,
       siac_v_dwh_mod_impegno_classe.desc_soggetto_classe_old AS desc_old,
       NULL::bpchar AS cf_old,
       NULL::character varying AS cf_estero_old,
       NULL::character varying AS partita_iva_old,
       siac_v_dwh_mod_impegno_classe.cod_tipo_sog_classe_old AS cod_tipo_old,
       siac_v_dwh_mod_impegno_classe.desc_tipo_sog_classe_old AS desc_tipo_old,
       siac_v_dwh_mod_impegno_classe.cod_soggetto_classe_new  AS cod_new,
       siac_v_dwh_mod_impegno_classe.desc_soggetto_classe_new AS desc_new,
       NULL::bpchar AS cf_new,
       NULL::character varying AS cf_estero_new,
       NULL::character varying AS partita_iva_new,
       siac_v_dwh_mod_impegno_classe.cod_tipo_sog_classe_new AS cod_tipo_new,
       siac_v_dwh_mod_impegno_classe.desc_tipo_sog_classe_new AS desc_tipo_new,
       siac_v_dwh_mod_impegno_classe.anno_atto_amministrativo,
       siac_v_dwh_mod_impegno_classe.num_atto_amministrativo,
       siac_v_dwh_mod_impegno_classe.cod_tipo_atto_amministrativo,
       siac_v_dwh_mod_impegno_classe.cod_sac,
       siac_v_dwh_mod_impegno_classe.desc_sac,
       siac_v_dwh_mod_impegno_classe.tipo_sac,
       siac_v_dwh_mod_impegno_classe.desc_stato_modifica,
       siac_v_dwh_mod_impegno_classe.tipo_modifica,
       siac_v_dwh_mod_impegno_classe.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_v_dwh_mod_impegno_classe
WHERE siac_v_dwh_mod_impegno_classe.tipo_modifica = 'CC'::text)
UNION
SELECT soggetto.ente_proprietario_id,
       soggetto.bil_anno_sogg AS bil_anno,
       soggetto.anno_impegno_sogg AS anno_impegno,
       soggetto.num_impegno_sogg AS num_impegno,
       soggetto.cod_movgest_ts_sogg AS cod_movgest_ts,
       soggetto.desc_movgest_ts_sogg AS desc_movgest_ts,
       soggetto.tipo_movgest_ts_sogg AS tipo_movgest_ts,
       soggetto.numero_modifica,
       soggetto.desc_modifica,
       soggetto.stato_modifica,
       soggetto.cod_tipo_modifica,
       soggetto.desc_tipo_modifica,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN soggetto.cod_soggeto_old
            ELSE classe.cod_soggetto_classe_old
            END AS cod_old,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN soggetto.desc_soggetto_old
            ELSE classe.desc_soggetto_classe_old
            END AS desc_old,
       soggetto.cf_old,
       soggetto.cf_estero_old,
       soggetto.partita_iva_old,
       classe.cod_tipo_sog_classe_old AS cod_tipo_old,
       classe.desc_tipo_sog_classe_old AS desc_tipo_old,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN classe.cod_soggetto_classe_new
            ELSE soggetto.cod_soggeto_new
            END AS cod_new,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN classe.desc_soggetto_classe_new
            ELSE soggetto.desc_soggetto_new
            END AS desc_new,
       soggetto.cf_new,
       soggetto.cf_estero_new,
       soggetto.partita_iva_new,
       classe.cod_tipo_sog_classe_new AS cod_tipo_new,
       classe.desc_tipo_sog_classe_new AS desc_tipo_new,
       soggetto.anno_atto_amministrativo,
       soggetto.num_atto_amministrativo,
       soggetto.cod_tipo_atto_amministrativo,
       soggetto.cod_sac,
       soggetto.desc_sac,
       soggetto.tipo_sac,
       soggetto.desc_stato_modifica,
       soggetto.tipo_modifica,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN classe.data_creazione
            ELSE soggetto.data_creazione
            END AS data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_v_dwh_mod_impegno_sogg soggetto,
     siac_v_dwh_mod_impegno_classe classe
WHERE soggetto.ente_proprietario_id = classe.ente_proprietario_id
AND   soggetto.bil_anno_sogg::text = classe.bil_anno_classe::text
AND   soggetto.anno_impegno_sogg = classe.anno_impegno_classe
AND   soggetto.num_impegno_sogg = classe.num_impegno_classe
AND   soggetto.cod_movgest_ts_sogg::text = classe.cod_movgest_ts_classe::text
AND   soggetto.desc_movgest_ts_sogg::text = classe.desc_movgest_ts_classe::text
AND   soggetto.tipo_movgest_ts_sogg::text = classe.tipo_movgest_ts_classe::text
AND   soggetto.numero_modifica = classe.numero_modifica
AND   soggetto.desc_modifica::text = classe.desc_modifica::text
AND   soggetto.stato_modifica::text = classe.stato_modifica::text
AND   soggetto.cod_tipo_modifica::text = classe.cod_tipo_modifica::text
AND   soggetto.desc_tipo_modifica::text = classe.desc_tipo_modifica::text
AND   soggetto.anno_atto_amministrativo::text = classe.anno_atto_amministrativo::text
AND   soggetto.num_atto_amministrativo = classe.num_atto_amministrativo
AND   soggetto.cod_tipo_atto_amministrativo::text = classe.cod_tipo_atto_amministrativo::text
AND   soggetto.cod_sac::text = classe.cod_sac::text
AND   soggetto.desc_sac::text = classe.desc_sac::text
AND   soggetto.tipo_sac::text = classe.tipo_sac::text
AND   soggetto.desc_stato_modifica::text = classe.desc_stato_modifica::text
AND   soggetto.tipo_modifica = classe.tipo_modifica;