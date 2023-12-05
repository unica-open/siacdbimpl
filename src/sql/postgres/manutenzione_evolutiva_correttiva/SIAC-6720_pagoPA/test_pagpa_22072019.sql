/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- controllare pagoapa_id=58 accertamento 80 non gira


select *
from pagopa_d_riconciliazione_errore er
where er.ente_proprietario_id=2

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select '51',
       'DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE',
       now(),
       'admin',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente
WHERE not exists
(select 1
 from pagopa_d_riconciliazione_errore errore
 where errore.ente_proprietario_id=ente.ente_proprietario_id
 and   errore.pagopa_ric_errore_code='51'
 and   errore.data_cancellazione is null
 )







select *
from siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2

select pago.*
from siac_t_file_pagopa pago
where pago.ente_proprietario_id=2
order by pago.file_pagopa_id
-- file_pagopa_id=5,6,7

select stato.file_pagopa_stato_code, pago.*
from siac_t_file_pagopa pago,siac_d_file_pagopa_stato stato
where pago.ente_proprietario_id=2
and   stato.file_pagopa_stato_id=pago.file_pagopa_stato_id
--and   stato.file_pagopa_stato_code='ACQUISITO'
--and   pago.data_cancellazione is null
--and   pago.validita_fine is null
order by pago.file_pagopa_id

begin;
update siac_t_file_pagopa pago
set    data_cancellazione=now()
from siac_d_file_pagopa_stato stato
where pago.ente_proprietario_id=2
and   stato.file_pagopa_stato_id=pago.file_pagopa_stato_id
and   stato.file_pagopa_stato_code='ACQUISITO'
and   pago.file_pagopa_id!=58
and   pago.data_cancellazione is null
and   pago.validita_fine is null


ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=190 ANNOBILANCIOELAB=2019. VERIFICA ESISTENZA DETTAGLI DI RICONCILIAZIONE DA ELABORARE.  SOGGETTO INESISTENTE PER DATI DI DETTAGLIO-FATT.  AGGIORNAMENTO SIAC_T_FILE_PAGOPA.CHIUSURA - CHIUSURA - CHIUSURA - CHIUSURA - CHIUSURA - CHIUSURA - ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=190 ANNOBILANCIOELAB=2019. AGGIORNAMENTO PAGOPA_T_ELABORAZIONE IN STATO=ELABORATO_KO. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_OK. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC.
ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=191 ANNOBILANCIOELAB=2019. VERIFICA ESISTENZA DETTAGLI DI RICONCILIAZIONE DA ELABORARE.  SOGGETTO INESISTENTE PER DATI DI DETTAGLIO-FATT.  AGGIORNAMENTO SIAC_T_FILE_PAGOPA.CHIUSURA - CHIUSURA - CHIUSURA - CHIUSURA - CHIUSURA - CHIUSURA - ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=191 ANNOBILANCIOELAB=2019. AGGIORNAMENTO PAGOPA_T_ELABORAZIONE IN STATO=ELABORATO_KO. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_OK. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC.


select *
from pagopa_d_riconciliazione_errore errore
where errore.ente_proprietario_id=2



select ric.*
from pagopa_t_riconciliazione ric
where ric.file_pagopa_id =58
order by ric.file_pagopa_id

select ric.pagopa_ric_id, ric.pagopa_ric_flusso_num_accertamento,  det.*
from pagopa_t_riconciliazione_det det, pagopa_t_riconciliazione ric
where ric.file_pagopa_id =58
and   det.pagopa_ric_id=ric.pagopa_ric_id

--RTOFNC53A64A182G
--189

select *
from pagopa_t_riconciliazione_det det
where det.pagopa_ric_det_id=189

select *
from siac_t_prov_cassa p
where p.ente_proprietario_id=2
and  p.provc_anno::integer=2019
select *
from siac_t_soggetto sog
where sog.ente_proprietario_id=2
and   sog.codice_fiscale like 'BTTCMN36A70L219W%'

select file_pagopa_id, ric.*
from pagopa_t_riconciliazione ric,siac_v_bko_accertamento_valido acc
where ric.file_pagopa_id =58
and   acc.ente_proprietario_id=2
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2019
and   acc.movgest_numero=ric.pagopa_ric_flusso_num_accertamento::integer
order by ric.file_pagopa_id

select stato.soggetto_stato_code, sog.*
from siac_v_bko_accertamento_valido acc,siac_r_movgest_ts_sog rsog,siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2019
and   acc.movgest_numero=80
and   rsog.movgest_ts_id=acc.movgest_ts_id
and   sog.soggetto_id=rsog.soggetto_id
and   rs.soggetto_id=sog.soggetto_id
and   stato.soggetto_stato_id=rs.soggetto_stato_id
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null

select ACC.*
from siac_v_bko_accertamento_valido acc,siac_r_movgest_ts_sog rsog,siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2019
and   acc.movgest_numero=81
and   rsog.movgest_ts_id=acc.movgest_ts_id
and   sog.soggetto_id=rsog.soggetto_id
and   rs.soggetto_id=sog.soggetto_id
and   stato.soggetto_stato_id=rs.soggetto_stato_id
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null

begin;
update siac_r_movgest_ts_sog rsog
set    data_cancellazione=now()
from siac_v_bko_accertamento_valido acc
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2019
and   acc.movgest_numero=80
and   rsog.movgest_ts_id=acc.movgest_ts_id
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null


select ric.pagopa_ric_errore_id, ric.file_pagopa_id, ric.*
from pagopa_t_riconciliazione_doc ric
where ric.file_pagopa_id =58
order by ric.pagopa_ric_doc_id desc



select stato.pagopa_elab_stato_code,
      pago.*
from pagopa_t_elaborazione pago,pagopa_d_elaborazione_stato stato
where pago.ente_proprietario_id=2
and   stato.pagopa_elab_stato_id=pago.pagopa_elab_stato_id

ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=193 ANNOBILANCIOELAB=2019. VERIFICA ESISTENZA DETTAGLI DI RICONCILIAZIONE DA ELABORARE.  DATI NON PRESENTI. AGGIORNAMENTO PAGOPA_T_ELABORAZIONE.
select *
from pagopa_t_riconciliazione ric
where ric.file_pagopa_id in (55,58,60)


select *
from pagopa_t_riconciliazione ric
where ric.pagopa_ric_flusso_num_accertamento=80


select det.pagopa_det_data_pagamento, det.*
from pagopa_t_riconciliazione_det det

select *
from siac_t_soggetto sog
where sog.ente_proprietario_id=2
and   sog.soggetto_code='306630'

select  pago.*
from siac_t_file_pagopa pago
where pago.ente_proprietario_id=2
order by pago.file_pagopa_id




select attr.attr_code, rattr.boolean,rattr.bil_elem_attr_id
from siac_v_bko_accertamento_valido acc,siac_t_movgest_ts ts,
     siac_r_movgest_ts_attr rattr,siac_t_attr attr
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2019
and   acc.movgest_numero=81
and   ts.movgest_ts_id=acc.movgest_ts_id
and   rattr.movgest_ts_id=acc.movgest_ts_id
and   attr.attr_id=rattr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
-- 1337640








rollback;
begin;
select *
from fnc_pagopa_t_elaborazione_riconc
(
  2,--enteproprietarioid integer,
  'test_pagopa_2019',--loginoperazione varchar,
  now()::timestamp--dataelaborazione timestamp
);

ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=197 ANNOBILANCIOELAB=2019.INSERIMENTO DOCUMENTO PER SOGGETTO=284268. VOCE TF10. STRUTTURA AMMINISTRATIVA  . AGGIORNAMENTO PAGOPA_T_RICONCILIAZIONE_DOC PER SUBDOC_ID.ERRORE:    ERRORE IN AGGIORNAMENTO.
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=193 ANNOBILANCIOELAB=2019. VERIFICA ESISTENZA DETTAGLI DI RICONCILIAZIONE DA ELABORARE.  DATI NON PRESENTI..
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=197 ANNOBILANCIOELAB=2019.INSERIMENTO DOCUMENTO PER SOGGETTO=284268. VOCE TF10. STRUTTURA AMMINISTRATIVA  . AGGIORNAMENTO PAGOPA_T_RICONCILIAZIONE_DOC PER SUBDOC_ID.ERRORE:    ERRORE IN AGGIORNAMENTO.
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=198 ANNOBILANCIOELAB=2019.INSERIMENTO DOCUMENTO PER SOGGETTO=284268. VOCE TF10. STRUTTURA AMMINISTRATIVA  . AGGIORNAMENTO PAGOPA_T_RICONCILIAZIONE_DOC PER SUBDOC_ID.ERRORE:    ERRORE IN AGGIORNAMENTO.
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=200 ANNOBILANCIOELAB=2019. VERIFICA ESISTENZA DETTAGLI DI RICONCILIAZIONE DA ELABORARE.  DATI NON PRESENTI..

select r.pagopa_ric_flusso_num_provvisorio, ric.*
from pagopa_t_riconciliazione_doc ric,pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione r
where ric.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   flusso.pagopa_elab_id=201
and   r.pagopa_ric_id=ric.pagopa_ric_id
-- 589
select * from pagopa_bck_t_subdoc b
where b.pagopa_elab_id=193;

select tipod.doc_tipo_code,
       sog.soggetto_code, sog.soggetto_desc,
       docu.doc_anno,
       docu.doc_numero,
       docu.doc_desc,
       docu.doc_importo,
       docu.doc_data_emissione,
       docu.doc_data_scadenza,
       sub.subdoc_data_scadenza,
       sub.subdoc_numero,
       sub.subdoc_desc,
       doc.pagopa_ric_doc_voce_code,
       doc.pagopa_ric_doc_voce_desc,
       doc.pagopa_ric_doc_sottovoce_code,
       doc.pagopa_ric_doc_sottovoce_desc,
       sub.subdoc_importo,
       doc.pagopa_ric_doc_sottovoce_importo,
       doc.pagopa_ric_doc_anno_accertamento,
       doc.pagopa_ric_doc_num_accertamento,
       acc.movgest_anno,
       acc.movgest_numero,
       flusso.pagopa_elab_flusso_anno_provvisorio,
       flusso.pagopa_elab_flusso_num_provvisorio,
       prov.provc_anno,
       prov.provc_numero,
       doc.pagopa_ric_doc_str_amm,
       c.classif_code,
       docu.doc_id

from  pagopa_t_riconciliazione_doc doc, pagopa_t_riconciliazione ric,pagopa_t_elaborazione_flusso flusso,
      siac_t_subdoc sub , siac_r_doc_sog rsog, siac_t_soggetto sog,
      siac_r_subdoc_movgest_ts rsub, siac_v_bko_accertamento_valido acc,
      siac_r_subdoc_prov_cassa rprov, siac_t_prov_cassa prov,siac_d_doc_tipo tipod,
      siac_t_doc docu left join siac_r_doc_class rc join siac_t_class c join siac_d_class_tipo tipo
                                                                              on ( tipo.classif_tipo_id=c.classif_tipo_id and tipo.classif_tipo_code in ('CDC','CDR') )
                                                         on (rc.classif_id=c.classif_id )
      on ( rc.doc_id=docu.doc_id)
where  flusso.pagopa_elab_id=201
and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and    ric.pagopa_ric_id=doc.pagopa_ric_id
and    sub.subdoc_id=doc.pagopa_ric_doc_subdoc_id
and    docu.doc_id=sub.doc_id
and    rsog.doc_id=docu.doc_id
and    sog.soggetto_id=rsog.soggetto_id
and    rsub.subdoc_id=sub.subdoc_id
and    acc.movgest_ts_id=rsub.movgest_ts_id
and    rprov.subdoc_id=sub.subdoc_id
and    prov.provc_id=rprov.provc_id
and    prov.provc_id=doc.pagopa_ric_doc_provc_id
and    tipod.doc_tipo_id=docu.doc_tipo_id
--and    tipod.doc_tipo_code='IPA'
order by docu.doc_id,sub.subdoc_id

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select '51',
       'DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE',
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente
WHERE not exists
(select 1
 from pagopa_d_riconciliazione_errore errore
 where errore.ente_proprietario_id=ente.ente_proprietario_id
 and   errore.pagopa_ric_errore_code='51'
 and   errore.data_cancellazione is null
 );

insert into siac_t_attr
(
 attr_code,
 attr_desc,
 attr_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'flagSenzaNumero',
       'flagSenzaNumero',
       tipo.attr_tipo_id,
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente , siac_d_attr_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.attr_tipo_code='B'
and   not exists
(
select 1
from siac_t_attr attr
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_tipo_id=tipo.attr_tipo_id
and   attr.attr_code='flagSenzaNumero'
and   attr.data_cancellazione is null
);


insert into siac_r_doc_tipo_attr
(
	doc_tipo_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select tipo.doc_tipo_id,
       attr.attr_id,
       'S',
       now(),
       'SIAC-6963',
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente, siac_t_attr attr,   siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='flagSenzaNumero'
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.doc_tipo_code in ('COR','FTV')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'
and   not exists
(select 1
 from  siac_r_doc_tipo_attr r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.doc_tipo_id=tipo.doc_tipo_id
 and   r.attr_id=attr.attr_id
 and   r.data_cancellazione is null
);pago.ente_proprietario_id=2
order by pago.file_pagopa_id




select attr.attr_code, rattr.boolean,rattr.bil_elem_attr_id
from siac_v_bko_accertamento_valido acc,siac_t_movgest_ts ts,
     siac_r_movgest_ts_attr rattr,siac_t_attr attr
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2019
and   acc.movgest_numero=81
and   ts.movgest_ts_id=acc.movgest_ts_id
and   rattr.movgest_ts_id=acc.movgest_ts_id
and   attr.attr_id=rattr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
-- 1337640








rollback;
begin;
select *
from fnc_pagopa_t_elaborazione_riconc
(
  2,--enteproprietarioid integer,
  'test_pagopa_2019',--loginoperazione varchar,
  now()::timestamp--dataelaborazione timestamp
);

ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=197 ANNOBILANCIOELAB=2019.INSERIMENTO DOCUMENTO PER SOGGETTO=284268. VOCE TF10. STRUTTURA AMMINISTRATIVA  . AGGIORNAMENTO PAGOPA_T_RICONCILIAZIONE_DOC PER SUBDOC_ID.ERRORE:    ERRORE IN AGGIORNAMENTO.
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=193 ANNOBILANCIOELAB=2019. VERIFICA ESISTENZA DETTAGLI DI RICONCILIAZIONE DA ELABORARE.  DATI NON PRESENTI..
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=197 ANNOBILANCIOELAB=2019.INSERIMENTO DOCUMENTO PER SOGGETTO=284268. VOCE TF10. STRUTTURA AMMINISTRATIVA  . AGGIORNAMENTO PAGOPA_T_RICONCILIAZIONE_DOC PER SUBDOC_ID.ERRORE:    ERRORE IN AGGIORNAMENTO.
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=198 ANNOBILANCIOELAB=2019.INSERIMENTO DOCUMENTO PER SOGGETTO=284268. VOCE TF10. STRUTTURA AMMINISTRATIVA  . AGGIORNAMENTO PAGOPA_T_RICONCILIAZIONE_DOC PER SUBDOC_ID.ERRORE:    ERRORE IN AGGIORNAMENTO.
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=200 ANNOBILANCIOELAB=2019. VERIFICA ESISTENZA DETTAGLI DI RICONCILIAZIONE DA ELABORARE.  DATI NON PRESENTI..

select r.pagopa_ric_flusso_num_provvisorio, ric.*
from pagopa_t_riconciliazione_doc ric,pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione r
where ric.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   flusso.pagopa_elab_id=201
and   r.pagopa_ric_id=ric.pagopa_ric_id
-- 589
select * from pagopa_bck_t_subdoc b
where b.pagopa_elab_id=193;

select tipod.doc_tipo_code,
       sog.soggetto_code, sog.soggetto_desc,
       docu.doc_anno,
       docu.doc_numero,
       docu.doc_desc,
       docu.doc_importo,
       docu.doc_data_emissione,
       docu.doc_data_scadenza,
       sub.subdoc_data_scadenza,
       sub.subdoc_numero,
       sub.subdoc_desc,
       doc.pagopa_ric_doc_voce_code,
       doc.pagopa_ric_doc_voce_desc,
       doc.pagopa_ric_doc_sottovoce_code,
       doc.pagopa_ric_doc_sottovoce_desc,
       sub.subdoc_importo,
       doc.pagopa_ric_doc_sottovoce_importo,
       doc.pagopa_ric_doc_anno_accertamento,
       doc.pagopa_ric_doc_num_accertamento,
       acc.movgest_anno,
       acc.movgest_numero,
       flusso.pagopa_elab_flusso_anno_provvisorio,
       flusso.pagopa_elab_flusso_num_provvisorio,
       prov.provc_anno,
       prov.provc_numero,
       doc.pagopa_ric_doc_str_amm,
       c.classif_code,
       docu.doc_id

from  pagopa_t_riconciliazione_doc doc, pagopa_t_riconciliazione ric,pagopa_t_elaborazione_flusso flusso,
      siac_t_subdoc sub , siac_r_doc_sog rsog, siac_t_soggetto sog,
      siac_r_subdoc_movgest_ts rsub, siac_v_bko_accertamento_valido acc,
      siac_r_subdoc_prov_cassa rprov, siac_t_prov_cassa prov,siac_d_doc_tipo tipod,
      siac_t_doc docu left join siac_r_doc_class rc join siac_t_class c join siac_d_class_tipo tipo
                                                                              on ( tipo.classif_tipo_id=c.classif_tipo_id and tipo.classif_tipo_code in ('CDC','CDR') )
                                                         on (rc.classif_id=c.classif_id )
      on ( rc.doc_id=docu.doc_id)
where  flusso.pagopa_elab_id=201
and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and    ric.pagopa_ric_id=doc.pagopa_ric_id
and    sub.subdoc_id=doc.pagopa_ric_doc_subdoc_id
and    docu.doc_id=sub.doc_id
and    rsog.doc_id=docu.doc_id
and    sog.soggetto_id=rsog.soggetto_id
and    rsub.subdoc_id=sub.subdoc_id
and    acc.movgest_ts_id=rsub.movgest_ts_id
and    rprov.subdoc_id=sub.subdoc_id
and    prov.provc_id=rprov.provc_id
and    prov.provc_id=doc.pagopa_ric_doc_provc_id
and    tipod.doc_tipo_id=docu.doc_tipo_id
--and    tipod.doc_tipo_code='IPA'
order by docu.doc_id,sub.subdoc_id

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select '51',
       'DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE',
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente
WHERE not exists
(select 1
 from pagopa_d_riconciliazione_errore errore
 where errore.ente_proprietario_id=ente.ente_proprietario_id
 and   errore.pagopa_ric_errore_code='51'
 and   errore.data_cancellazione is null
 );

insert into siac_t_attr
(
 attr_code,
 attr_desc,
 attr_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'flagSenzaNumero',
       'flagSenzaNumero',
       tipo.attr_tipo_id,
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente , siac_d_attr_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.attr_tipo_code='B'
and   not exists
(
select 1
from siac_t_attr attr
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_tipo_id=tipo.attr_tipo_id
and   attr.attr_code='flagSenzaNumero'
and   attr.data_cancellazione is null
);


insert into siac_r_doc_tipo_attr
(
	doc_tipo_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select tipo.doc_tipo_id,
       attr.attr_id,
       'S',
       now(),
       'SIAC-6963',
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente, siac_t_attr attr,   siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='flagSenzaNumero'
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.doc_tipo_code in ('COR','FTV')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'
and   not exists
(select 1
 from  siac_r_doc_tipo_attr r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.doc_tipo_id=tipo.doc_tipo_id
 and   r.attr_id=attr.attr_id
 and   r.data_cancellazione is null
);