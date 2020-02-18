/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW siac.siac_v_dwh_sogg_account_gruppo_sac;

CREATE OR REPLACE VIEW siac.siac_v_dwh_sogg_account_gruppo_sac(
    account_id,
    soggetto_code,
    soggetto_desc,
    codice_fiscale,
    inizio_validita_account,
    fine_validita_account,
    ente_id_su_cui_opera,
    ente_denominazione_su_cui_opera,
    gruppo_code,
    gruppo_desc,
    ente_id_appartenenza,
    ente_denominazione_appartenenza,
    codice_cdc,
    descrizione_cdc,
    codice_cdr,
    descrizione_cdr,
    email)
AS
    WITH sogg AS (
  SELECT d.account_id,
         a.soggetto_code,
         a.soggetto_desc,
         a.codice_fiscale,
         d.validita_inizio AS inizio_validita_account,
         d.validita_fine AS fine_validita_account,
         l.ente_proprietario_id AS ente_id_su_cui_opera,
         l.ente_denominazione AS ente_denominazione_su_cui_opera,
         f.gruppo_code,
         f.gruppo_desc,
         i.ente_proprietario_id AS ente_id_appartenenza,
         i.ente_denominazione AS ente_denominazione_appartenenza,
         a.soggetto_id
  FROM siac_t_soggetto a,
       siac_r_soggetto_ruolo b,
       siac_d_ruolo c,
       siac_t_account d,
       siac_r_gruppo_account e,
       siac_t_gruppo f,
       siac_t_ente_proprietario i,
       siac_t_ente_proprietario l
  WHERE a.soggetto_id = b.soggetto_id AND
        c.ruolo_id = b.ruolo_id AND
        c.ruolo_code::text = 'RUOLO_OP'::text AND
        d.soggeto_ruolo_id = b.soggeto_ruolo_id AND
        e.account_id = d.account_id AND
        f.gruppo_id = e.gruppo_id AND
        i.ente_proprietario_id = a.ente_proprietario_id AND
        (l.ente_proprietario_id <> ALL (ARRAY [ 7, 8 ])) AND
        (l.ente_proprietario_id <> ALL (ARRAY [ 1, 2, 3 ])) AND
        upper(a.soggetto_code::text) !~~ 'DEMO%'::text AND
        l.ente_proprietario_id = f.ente_proprietario_id),
      cdc AS (
    SELECT n.classif_code AS codice_cdc,
           n.classif_desc AS descrizione_cdc,
           m.account_id
    FROM siac_r_account_class m,
         siac_t_class n,
         siac_d_class_tipo o
    WHERE n.classif_id = m.classif_id AND
          o.classif_tipo_id = n.classif_tipo_id AND
          o.classif_tipo_code::text = 'CDC'::text AND
          now() >= m.validita_inizio AND
          now() <= COALESCE(m.validita_fine::timestamp with time zone, now()))
,cdr AS(
        SELECT n.classif_code AS codice_cdr,
               n.classif_desc AS descrizione_cdr,
               m.account_id
        FROM siac_r_account_class m,
             siac_t_class n,
             siac_d_class_tipo o
        WHERE n.classif_id = m.classif_id AND
              o.classif_tipo_id = n.classif_tipo_id AND
              o.classif_tipo_code::text = 'CDR'::text AND
              now() >= m.validita_inizio AND
              now() <= COALESCE(m.validita_fine::timestamp with time zone, now()
                ))          
,email as
(select aa.recapito_desc email,aa.soggetto_id
From siac_t_recapito_soggetto aa,siac_d_recapito_modo bb
where aa.recapito_modo_id=bb.recapito_modo_id and bb.recapito_modo_code='email'
and aa.data_cancellazione is null
and bb.data_cancellazione is null
)          
  SELECT  
sogg.account_id,
sogg.soggetto_code,
sogg.soggetto_desc,
sogg.codice_fiscale,
sogg.inizio_validita_account,
sogg.fine_validita_account,
sogg.ente_id_su_cui_opera,
sogg.ente_denominazione_su_cui_opera,
sogg.gruppo_code,
sogg.gruppo_desc,
sogg.ente_id_appartenenza,
sogg.ente_denominazione_appartenenza,
cdc.codice_cdc,
cdc.descrizione_cdc,
cdr.codice_cdr,
cdr.descrizione_cdr,
email.email
FROM sogg
           LEFT JOIN cdc ON cdc.account_id = sogg.account_id
           LEFT JOIN cdr ON cdr.account_id = sogg.account_id
           LEFT JOIN email ON sogg.soggetto_id=email.soggetto_id
          ORDER BY sogg.ente_id_su_cui_opera,
                   sogg.soggetto_code,
                   sogg.gruppo_code;