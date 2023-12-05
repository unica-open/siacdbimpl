<<<<<<< HEAD
-- siac.v_simop_fatt_daricev source
drop MATERIALIZED VIEW siac.v_simop_fatt_daricev;


CREATE MATERIALIZED VIEW siac.v_simop_fatt_daricev
TABLESPACE pg_default
AS SELECT DISTINCT sog.soggetto_code AS codice_anagrafico_fornitore,
    sog.soggetto_desc AS nome_partecipata,
    sog.codice_fiscale::character varying(16) AS codice_fiscale_partecipata,
    sog.partita_iva AS p_iva_partecipata,
    'PR'::text AS stato_documento,
    fat.codice_destinatario AS ipa_struttura_capitolina,
    ' '::text AS responsabile_procedura,
    portale.identificativo_sdi,
    ''::text AS progressivo_invio_sdi,
    ''::text AS data_ricezione_sdi,
    ''::text AS data_registrazione,
    ''::text AS tipo_documento,
    ''::text AS data_fattura,
    fat.numero AS n_fattura,
    to_char(fat.data, 'YYYY'::text) AS anno_fattura,
    fat.importo_totale_documento AS importo_totale_fattura,
    fat.importo_totale_netto AS importo_imponibile,
    fat.importo_totale_documento - fat.importo_totale_netto AS importo_iva,
    ''::text AS codice_sospensione,
    ''::text AS data_sospensione,
    ''::text AS codice_cig,
    ''::text AS codice_cup,
    ''::text AS anno_impegno,
    ''::text AS numero_impegno,
    ''::text AS numero_sub_impegno,
    ''::text AS importo_rata_fattura,
    ''::text AS codice_di_non_pagabilita,
    ''::text AS numero_liquidazione,
    ''::text AS importo_liquidato,
    ''::text AS importo_pagato_entro,
    ''::text AS importo_pagato_oltre,
    ''::text AS numero_mandato,
    ''::text AS id,
    ''::text AS data_chiusura
   FROM sirfel_t_fattura fat,
    siac_t_soc_partecipate part,
    siac_t_soggetto sog,
    sirfel_t_prestatore stp,
    sirfel_t_portale_fatture portale
  WHERE fat.stato_fattura = 'N'::bpchar AND stp.id_prestatore = fat.id_prestatore AND portale.id_fattura = fat.id_fattura AND portale.esito_utente_codice::text = part.codice_fiscale::text AND part.anno::text = to_char(fat.data, 'YYYY'::text) AND portale.esito_utente_codice::text = sog.codice_fiscale::character varying::text
WITH DATA;
=======
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_fatt_daricev
AS SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale::CHARACTER VARYING(16) AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        'PR' AS stato_documento,
        fat.codice_destinatario AS ipa_struttura_capitolina,
        ' ' AS responsabile_procedura,
        portale.identificativo_sdi,
        '' AS progressivo_invio_sdi,
        '' AS data_ricezione_sdi,
        '' AS data_registrazione,
        '' AS tipo_documento,
        '' AS data_fattura,
        fat.numero AS n_fattura,
        to_char(fat.data, 'YYYY') AS anno_fattura,
        fat.importo_totale_documento AS importo_totale_fattura,
        fat.importo_totale_netto AS importo_imponibile,
        fat.importo_totale_documento - fat.importo_totale_netto AS importo_iva,
        '' AS codice_sospensione,
        '' AS data_sospensione,
        '' AS codice_cig,
        '' AS codice_cup,
        '' AS anno_impegno,
        '' AS numero_impegno,
        '' AS numero_sub_impegno,
        '' AS importo_rata_fattura,
        '' AS codice_di_non_pagabilita,
        '' AS numero_liquidazione,
        '' AS importo_liquidato,
        '' AS importo_pagato_entro,
        '' AS importo_pagato_oltre,
        '' AS numero_mandato,
        '' AS id,
        '' AS data_chiusura
    FROM sirfel_t_fattura fat,
        siac_t_soc_partecipate part,
        siac_t_soggetto sog,
        sirfel_t_prestatore stp,
        sirfel_t_portale_fatture portale
    WHERE fat.stato_fattura = 'N'
    AND stp.id_prestatore = fat.id_prestatore
    AND portale.id_fattura = fat.id_fattura
    AND portale.esito_utente_codice = part.codice_fiscale
    AND part.anno = to_char(fat.data, 'YYYY')
    AND portale.esito_utente_codice = sog.codice_fiscale
WITH DATA;
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
