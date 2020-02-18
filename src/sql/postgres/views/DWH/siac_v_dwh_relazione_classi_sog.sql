/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_relazione_classi_sog (
    ana_classe_code,
    soggetto_code,
    ente_proprietario_id,
    validita_inizio,
    validita_fine,
    soggetto_id)
AS
--------------- SOGGETTI LEGATI A CLASSI
SELECT
    a.soggetto_classe_code AS ana_classe_code,
    c.soggetto_code,
    a.ente_proprietario_id,
    b.validita_inizio, b.validita_fine,
    c.soggetto_id
FROM siac_d_soggetto_classe a, siac_r_soggetto_classe b, siac_t_soggetto c
WHERE a.data_cancellazione IS NULL
AND   a.soggetto_classe_id = b.soggetto_classe_id
AND   b.soggetto_id = c.soggetto_id
AND   c.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
union
SELECT
    a.soggetto_classe_code AS ana_classe_code,
    c.soggetto_code,
    a.ente_proprietario_id,
    b.validita_inizio, b.validita_fine,
    sog_sede.soggetto_id
FROM siac_d_soggetto_classe a, siac_r_soggetto_classe b, siac_t_soggetto c,
     siac_r_soggetto_relaz relaz,siac_d_relaz_tipo tipo,
     siac_t_soggetto sog_sede
WHERE a.soggetto_classe_id = b.soggetto_classe_id
AND   b.soggetto_id = c.soggetto_id
and   relaz.soggetto_id_da=c.soggetto_id
and   sog_sede.soggetto_id=relaz.soggetto_id_a
and   tipo.relaz_tipo_id=relaz.relaz_tipo_id
and   tipo.relaz_tipo_code='SEDE_SECONDARIA'
and   a.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
and   relaz.data_cancellazione is null
and   sog_sede.data_cancellazione is null
order by 1;