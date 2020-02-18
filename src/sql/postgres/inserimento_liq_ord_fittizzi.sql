/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*Insert into siac_d_pcc_codice
  (pcccod_code,pcccod_desc,validita_inizio,ente_proprietario_id,login_operazione)
values
  ('00-ZIH','00-ZIH','01/01/2015'::timestamp,2,'admin');

Insert into siac_d_pcc_codice
  (pcccod_code,pcccod_desc,validita_inizio,ente_proprietario_id,login_operazione)
values
  ('99999','99999','01/01/2015'::timestamp,2,'admin');
Insert into siac_d_pcc_codice
  (pcccod_code,pcccod_desc,validita_inizio,ente_proprietario_id,login_operazione)
values
  ('99999','99999','01/01/2015'::timestamp,1,'admin');

select * from siac_d_pcc_codice where ente_proprietario_id=1
PCC precaricato */

select * from siac_t_bil
where ente_proprietario_id=14
select * from siac_t_periodo
where ente_proprietario_id=14

select * from fnc_get_bilancio(14,('2015'::INTEGER-1)::varchar)
-- INSERT NECESSARI PER LA MIGRAZIONE DEI DOCUMENTI.
-- CREAZIONE LIQUIDAZIONE FITTIZIA
-- cambiare solo l'ente!
insert into siac_t_liquidazione
(liq_anno,liq_numero,liq_desc,liq_emissione_data,liq_importo,bil_id, validita_inizio,ente_proprietario_id, login_operazione)
select
9999,999999,'QUOTE DOC SPESA PAGATE','01/01/2014'::timestamp,0,bilancio.idbilancio,'01/01/2014'::timestamp,14,'admin'
from fnc_get_bilancio(14,('2015'::INTEGER-1)::varchar) bilancio

select * from siac_t_liquidazione where  ente_proprietario_id = 14 and liq_anno=9999

-- CREAZIONE ORDINATIVO FITTIZIO (TESTATA E RELATIVO TS)
-- cambiare solo l'ente!
insert into siac_t_ordinativo (ord_anno, ord_numero,ord_desc,ord_tipo_id,ord_cast_cassa,ord_cast_competenza,ord_cast_emessi,ord_beneficiariomult, ord_emissione_data,bil_id,validita_inizio,ente_proprietario_id, login_operazione, login_creazione)
select
9999,999999,'DOC QUOTE SPESA PAGATE',d.ord_tipo_id,0,0,0,false,'01/01/2014'::timestamp,bilancio.idbilancio,'01/01/2014'::timestamp,14,'admin','admin'
from fnc_get_bilancio(14,('2015'::INTEGER-1)::varchar) bilancio
, siac_d_ordinativo_tipo d
where d.ente_proprietario_id=14
and d.ord_tipo_code = 'P'
and d.data_cancellazione is null and
        date_trunc('day',now())>=date_trunc('day',d.validita_inizio) and
        (date_trunc('day',now())<=date_trunc('day',d.validita_fine)
            or d.validita_fine is null);

insert into siac_t_ordinativo (ord_anno, ord_numero,ord_desc,ord_tipo_id,ord_cast_cassa,ord_cast_competenza,ord_cast_emessi,ord_beneficiariomult, ord_emissione_data,bil_id,validita_inizio,ente_proprietario_id, login_operazione, login_creazione)
select
9999,999999,'DOC QUOTE ENTRATA INCASSATE',d.ord_tipo_id,0,0,0,false,'01/01/2014'::timestamp,bilancio.idbilancio,'01/01/2014'::timestamp,14,'admin','admin'
from fnc_get_bilancio(14,('2015'::INTEGER-1)::varchar) bilancio
, siac_d_ordinativo_tipo d
where d.ente_proprietario_id=14
and d.ord_tipo_code = 'I'
and d.data_cancellazione is null and
        date_trunc('day',now())>=date_trunc('day',d.validita_inizio) and
        (date_trunc('day',now())<=date_trunc('day',d.validita_fine)
            or d.validita_fine is null);

select * from siac_d_ordinativo_tipo
where ente_proprietario_id=14

select * from siac_t_ordinativo where ente_proprietario_id = 14 and ord_tipo_id = 23 and ord_numero = 999999

select * from siac_t_ordinativo where ente_proprietario_id = 14 and ord_tipo_id = 24 and ord_numero = 999999



insert into siac_t_ordinativo_ts (ord_ts_code, ord_ts_desc,ord_id,validita_inizio,ente_proprietario_id, login_operazione)
values
(999999,'DOC QUOTE SPESA PAGATE',193,'01/01/2014'::timestamp,14,'admin')
insert into siac_t_ordinativo_ts (ord_ts_code, ord_ts_desc,ord_id,validita_inizio,ente_proprietario_id, login_operazione)
values
(999999,'DOC QUOTE ENTRATA INCASSATE',194,'01/01/2014'::timestamp,14,'admin')

select * from siac_t_ordinativo_ts t
where ente_proprietario_id=14
and  t.ord_ts_code='999999'

select  * from siac_d_class_tipo
where ente_proprietario_id=2

-- 46
-- 47

select * From siac_t_class
where classif_tipo_id=47
and classif_code like '603%'

select * From siac_t_class
where classif_tipo_id=46
and classif_code like '603%'
