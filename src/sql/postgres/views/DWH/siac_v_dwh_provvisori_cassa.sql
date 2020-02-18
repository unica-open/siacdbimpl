/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_provvisori_cassa(
    ente_proprietario_id,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    provc_causale,
    provc_subcausale,
    provc_denom_soggetto,
    provc_importo,
    provc_data_annullamento,
    provc_data_convalida,
    provc_data_emissione,
    provc_data_regolarizzazione,
    tipo_sac,
    codice_sac,
    provc_data_trasmissione,
    provc_accettato,
    provc_note,
    provc_conto_evidenza, -- 28.05.2018 Sofia siac-6126
    provc_descrizione_conto_evidenza) -- 28.05.2018 Sofia siac-6126
AS
WITH provv AS(
  SELECT a.ente_proprietario_id,
         b.provc_tipo_code,
         b.provc_tipo_desc,
         a.provc_anno,
         a.provc_numero,
         a.provc_causale,
         a.provc_subcausale,
         a.provc_denom_soggetto,
         a.provc_importo,
         a.provc_data_annullamento,
         a.provc_data_convalida,
         a.provc_data_emissione,
         a.provc_data_regolarizzazione,
         a.provc_id,
         a.provc_data_trasmissione,
         a.provc_accettato,
         a.provc_note
  FROM siac_t_prov_cassa a,
       siac_d_prov_cassa_tipo b
  WHERE a.provc_tipo_id = b.provc_tipo_id AND
        a.data_cancellazione IS NULL), sac AS(
    SELECT n.classif_code AS codice_sac,
           n.classif_desc AS descrizione_cdc,
           o.classif_tipo_code AS tipo_sac,
           m.provc_id
    FROM siac_r_prov_cassa_class m,
         siac_t_class n,
         siac_d_class_tipo o
    WHERE n.classif_id = m.classif_id AND
          o.classif_tipo_id = n.classif_tipo_id AND
          (o.classif_tipo_code::text = ANY (ARRAY [ 'CDC'::text, 'CDR'::text ]))
  AND
          now() >= m.validita_inizio AND
          now() <= COALESCE(m.validita_fine::timestamp with time zone, now())
  AND
          m.data_cancellazione IS NULL),
  provc_conto_evidenza as -- 28.05.2018 Sofia siac-6126
  (
      select query.provc_id,
           query.oil_ricevuta_id,
           query.conto_evidenza,
           query.descrizione_conto_evidenza
  from
  (
  with
  rprov as
  (
  select *
  from siac_r_prov_cassa_oil_ricevuta r
  where r.data_cancellazione is null
  and   r.validita_fine is null
  ),
  ricevuta as
  (
  select oil.*
  from siac_t_oil_ricevuta oil,siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='P'
  and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
  and   oil.oil_ricevuta_errore_id is null
  and   oil.data_cancellazione is null
  and   oil.validita_fine is null
  ),
  giocassa as
  (
  select
         gio.flusso_elab_mif_id,
         gio.mif_t_giornalecassa_id,
         gio.conto_evidenza,
         gio.descrizione_conto_evidenza
  from mif_t_giornalecassa gio
  where gio.tipo_documento in ( 'SOSPESO ENTRATA','SOSPESO USCITA')
  and   gio.data_cancellazione is null
  and   gio.validita_fine is null
  )
  select rprov.provc_id,
         rprov.oil_ricevuta_id, ricevuta.oil_ricevuta_tipo_id,
         ricevuta.oil_progr_ricevuta_id, ricevuta.flusso_elab_mif_id,
         giocassa.conto_evidenza, giocassa.descrizione_conto_evidenza
  from  rprov, ricevuta, giocassa
  where ricevuta.oil_ricevuta_id=rprov.oil_ricevuta_id
  and   giocassa.flusso_elab_mif_id=ricevuta.flusso_elab_mif_id
  and   giocassa.mif_t_giornalecassa_id=ricevuta.oil_progr_ricevuta_id
  ) query, siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='P'
  and   tipo.oil_ricevuta_tipo_id=query.oil_ricevuta_tipo_id
  )
   SELECT provv.ente_proprietario_id,
             provv.provc_tipo_code,
             provv.provc_tipo_desc,
             provv.provc_anno,
             provv.provc_numero,
             provv.provc_causale,
             provv.provc_subcausale,
             provv.provc_denom_soggetto,
             provv.provc_importo,
             provv.provc_data_annullamento,
             provv.provc_data_convalida,
             provv.provc_data_emissione,
             provv.provc_data_regolarizzazione,
             sac.tipo_sac,
             sac.codice_sac,
             provv.provc_data_trasmissione,
             provv.provc_accettato,
             provv.provc_note,
             provc_conto_evidenza.conto_evidenza, -- 28.05.2018 Sofia siac-6126
             provc_conto_evidenza.descrizione_conto_evidenza -- 28.05.2018 Sofia siac-6126
      FROM provv
           LEFT JOIN sac ON sac.provc_id = provv.provc_id
           left join provc_conto_evidenza on (provv.provc_id=provc_conto_evidenza.provc_id) -- 28.05.2018 Sofia siac-6126
      ORDER BY provv.ente_proprietario_id;