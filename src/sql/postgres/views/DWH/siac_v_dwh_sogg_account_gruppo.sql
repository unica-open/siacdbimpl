/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop view siac_v_dwh_sogg_account_gruppo;

CREATE VIEW siac.siac_v_dwh_sogg_account_gruppo as
select * from (
with ut as  (  SELECT a.soggetto_id,
                a.soggetto_code,
                a.soggetto_desc,
                d.validita_inizio AS inizio_validita_account,
                d.validita_fine AS fine_validita_account,
                l.ente_proprietario_id AS ente_id_su_cui_opera,
                l.ente_denominazione AS ente_denominazione_su_cui_opera,
                f.gruppo_code,
                f.gruppo_desc,
                i.ente_proprietario_id AS ente_id_appartenenza,
                i.ente_denominazione AS ente_denominazione_appartenenza,
                d.account_id
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
              -- (l.ente_proprietario_id <> ALL (ARRAY [ 7, 8 ])) AND
               case when current_database()='PRODBIL1-MULT' then l.ente_proprietario_id not in (1,2,3,7,8) 
               else l.ente_proprietario_id not in (7,8) 
               end  AND
               upper(a.soggetto_code::text) !~~ 'DEMO%'::text AND
               l.ente_proprietario_id = f.ente_proprietario_id
               and a.data_cancellazione is null
               and b.data_cancellazione is null
               and c.data_cancellazione is null
               and d.data_cancellazione is null
              and e.data_cancellazione is null
                and f.data_cancellazione is null
                            )
, email AS
( SELECT aa.recapito_desc AS email,
                aa.soggetto_id
         FROM siac_t_recapito_soggetto aa,
              siac_d_recapito_modo bb
         WHERE aa.recapito_modo_id = bb.recapito_modo_id AND
               bb.recapito_modo_code::text = 'email'::text
               and aa.data_cancellazione is null
               and bb.data_cancellazione is null) 
, sac as (select 
a.account_id, 
b.classif_code codice_sac,
b.classif_desc descrizione_sac,
c.classif_tipo_code tipo_sac
 from siac_r_account_class a,siac_t_class b,siac_d_class_tipo c
where a.classif_id=b.classif_id and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code in ('CDC','CDR')
and now() between a.validita_inizio and coalesce (a.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)                         
select  
ut.soggetto_id,
ut.soggetto_code,
         ut.soggetto_desc,
         ut.inizio_validita_account,
         ut.fine_validita_account,
         ut.ente_id_su_cui_opera,
         ut.ente_denominazione_su_cui_opera,
         ut.gruppo_code,
         ut.gruppo_desc,
         ut.ente_id_appartenenza,
         ut.ente_denominazione_appartenenza,
         email.email
      ,      sac.codice_sac,
sac.descrizione_sac,
sac.tipo_sac
from ut left join email
 on ut.soggetto_id = email.soggetto_id  
 left join sac on ut.account_id=sac.account_id      
) as tb 
   ORDER BY tb.ente_id_su_cui_opera,
           tb.soggetto_code,
           tb.gruppo_code;
