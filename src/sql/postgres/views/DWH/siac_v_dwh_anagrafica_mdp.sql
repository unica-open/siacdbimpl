/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_anagrafica_mdp (
    ente_proprietario_id,
    famiglia,
    soggetto_mdp,
    soggetto_ricevente,
    gruppo_code,
    accredito_tipo_code,
    accredito_tipo_desc,
    quietanziante,
    quietanzante_nascita_data,
    quietanziante_nascita_luogo,
    quietanziante_nascita_stato,
    bic,
    contocorrente,
    contocorrente_intestazione,
    iban,
    note,
    data_scadenza,
    ordine,
    soggetto_mdp_id,
    soggetto_ricevente_id,
    modpag_id)
AS
SELECT sog.ente_proprietario_id, 'CESSIONI'::text AS famiglia,
            sogcess.soggetto_code AS soggetto_mdp,
            sog.soggetto_code AS soggetto_ricevente,
            grp.accredito_gruppo_code AS gruppo_code, dat.accredito_tipo_code,
            dat.accredito_tipo_desc, tm.quietanziante,
            tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo,
            tm.quietanziante_nascita_stato, tm.bic, tm.contocorrente,
            tm.contocorrente_intestazione, tm.iban, tm.note, tm.data_scadenza,
            ordine.ordine, sogcess.soggetto_id AS soggetto_mdp_id,
            sog.soggetto_id AS soggetto_ricevente_id, tm.modpag_id
FROM siac_t_modpag tm, siac_d_accredito_tipo dat,
            siac_t_soggetto sog, siac_r_soggrel_modpag rrelaz,
            siac_r_soggetto_relaz relaz, siac_t_soggetto sogcess,
            siac_d_accredito_gruppo grp, siac_r_modpag_ordine ordine
WHERE dat.accredito_tipo_id = tm.accredito_tipo_id AND grp.accredito_gruppo_id
    = dat.accredito_gruppo_id AND sog.soggetto_id = relaz.soggetto_id_a AND rrelaz.modpag_id = tm.modpag_id AND sogcess.soggetto_id = relaz.soggetto_id_da AND rrelaz.soggetto_relaz_id = relaz.soggetto_relaz_id AND ordine.soggrelmpag_id = rrelaz.soggrelmpag_id AND tm.data_cancellazione IS NULL AND ordine.data_cancellazione IS NULL AND rrelaz.data_cancellazione IS NULL AND relaz.data_cancellazione IS NULL
UNION
SELECT sog.ente_proprietario_id, 'NON CESSIONI'::text AS famiglia,
            sog.soggetto_code AS soggetto_mdp,
            NULL::character varying AS soggetto_ricevente,
            grp.accredito_gruppo_code AS gruppo_code, dat.accredito_tipo_code,
            dat.accredito_tipo_desc, tm.quietanziante,
            tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo,
            tm.quietanziante_nascita_stato, tm.bic, tm.contocorrente,
            tm.contocorrente_intestazione, tm.iban, tm.note, tm.data_scadenza,
            ordine.ordine, sog.soggetto_id AS soggetto_mdp_id,
            NULL::integer AS soggetto_ricevente_id, tm.modpag_id
FROM siac_t_modpag tm, siac_d_accredito_tipo dat,
            siac_t_soggetto sog, siac_d_accredito_gruppo grp,
            siac_r_modpag_ordine ordine
WHERE dat.accredito_tipo_id = tm.accredito_tipo_id AND grp.accredito_gruppo_id
    = dat.accredito_gruppo_id AND sog.soggetto_id = tm.soggetto_id AND (grp.accredito_gruppo_code::text <> ALL (ARRAY['CSI'::character varying::text, 'CSC'::character varying::text])) AND ordine.modpag_id = tm.modpag_id AND tm.data_cancellazione IS NULL AND ordine.data_cancellazione IS NULL;