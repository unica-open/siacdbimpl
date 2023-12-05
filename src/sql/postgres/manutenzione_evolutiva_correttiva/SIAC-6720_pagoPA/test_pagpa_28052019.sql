/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select stato.pagopa_elab_stato_code, pa.*
from pagopa_t_elaborazione pa,pagopa_d_elaborazione_stato stato
where pa.ente_proprietario_id=2
and   stato.pagopa_elab_stato_id=pa.pagopa_elab_stato_id
-- 79


select r.file_pagopa_id, file.*
from pagopa_r_elaborazione_file r,
     siac_t_file_pagopa file
where r.pagopa_elab_id=79
and   file.file_pagopa_id=r.file_pagopa_id
and   r.data_cancellazione is null
and   r.validita_fine is null

select r.file_pagopa_id, stato.pagopa_elab_stato_code, flusso.*
from pagopa_r_elaborazione_file r,pagopa_t_elaborazione_flusso flusso,pagopa_d_elaborazione_stato stato,
     siac_t_file_pagopa file
where r.pagopa_elab_id=79
and   file.file_pagopa_id=r.file_pagopa_id
and   flusso.pagopa_elab_id=r.pagopa_elab_id
and   stato.pagopa_elab_stato_id=flusso.pagopa_elab_flusso_stato_id
and   r.data_cancellazione is null
and   r.validita_fine is null

select *
from pagopa_t_elaborazione_flusso flusso
where flusso.pagopa_elab_id=79


select distinct ric.pagopa_ric_file_id pagopa_file_id,
                    ric.pagopa_ric_flusso_id pagopa_flusso_id,
                    ric.pagopa_ric_flusso_anno_provvisorio pagopa_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio pagopa_num_provvisorio
    from pagopa_t_riconciliazione ric
    where ric.file_pagopa_id in ( 32,34)
  --  and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
  --  and   ric.data_cancellazione is null
   -- and   ric.validita_fine is null
    order by        ric.pagopa_ric_flusso_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio

 select r.file_pagopa_id,  ric.*
from pagopa_r_elaborazione_file r,pagopa_t_riconciliazione ric,
     siac_t_file_pagopa file
where r.pagopa_elab_id=79
and   file.file_pagopa_id=r.file_pagopa_id
and   ric.file_pagopa_id=file.file_pagopa_id
and   r.data_cancellazione is null
and   r.validita_fine is null


select r.file_pagopa_id, stato.pagopa_elab_stato_code,
       flusso.pagopa_elab_flusso_anno_provvisorio,flusso.pagopa_elab_flusso_num_provvisorio,
       flusso.pagopa_elab_flusso_id,
       flusso.pagopa_elab_flusso_provc_id

from pagopa_r_elaborazione_file r,pagopa_t_elaborazione_flusso flusso,pagopa_d_elaborazione_stato stato,
     siac_t_file_pagopa file,pagopa_t_riconciliazione_doc doc
where r.pagopa_elab_id=79
and   file.file_pagopa_id=r.file_pagopa_id
and   flusso.pagopa_elab_id=r.pagopa_elab_id
and   stato.pagopa_elab_stato_id=flusso.pagopa_elab_flusso_stato_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   r.data_cancellazione is null
and   r.validita_fine is null


select distinct ric.pagopa_ric_file_id pagopa_file_id,
                    ric.pagopa_ric_flusso_id pagopa_flusso_id,
                    ric.pagopa_ric_flusso_anno_provvisorio pagopa_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio pagopa_num_provvisorio
    from pagopa_t_riconciliazione ric
    where ric.file_pagopa_id in ( 32,34)
--  and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
  and   ric.data_cancellazione is null
and   ric.validita_fine is null
    order by        ric.pagopa_ric_flusso_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio


select              elab.pagopa_elab_id,
stato.pagopa_elab_stato_code,
                    ric.pagopa_ric_file_id pagopa_file_id,
                    ric.pagopa_ric_flusso_id pagopa_flusso_id,
                    ric.pagopa_ric_flusso_anno_provvisorio pagopa_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio pagopa_num_provvisorio,
                    flusso.pagopa_elab_flusso_anno_provvisorio,
                    flusso.pagopa_elab_flusso_num_provvisorio,
                    flusso.pagopa_elab_flusso_tot_pagam,
                    flusso.pagopa_elab_flusso_data,
                    doc.*
from pagopa_t_riconciliazione ric,pagopa_r_elaborazione_file r,pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
where ric.file_pagopa_id in ( 32,34)
  --  and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
  and   r.file_pagopa_id=ric.file_pagopa_id
  and   elab.pagopa_elab_id=r.pagopa_elab_id
  and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
  and   elab.pagopa_elab_id=91
  and   flusso.pagopa_elab_id=elab.pagopa_elab_id
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   ric.pagopa_ric_id=doc.pagopa_ric_id
  and   ric.data_cancellazione is null
   and   ric.validita_fine is null
    order by        ric.pagopa_ric_flusso_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio

----------------------------- da qui d aqui 32,34


select *
from pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=2

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
--and   pago.data_cancellazione is null
--and   pago.validita_fine is null
order by pago.file_pagopa_id

ELABORAZIONE PAGOPA PER FILE_PAGOPA_ID=32.AGGIORNAMENTO SIAC_T_FILE_PAGOPA PER ELABORAZIONE IN CORSO. AGGIORNAMENTO PER ERR.=36.CHIUSURA - CHIUSURA - ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=110 ANNOBILANCIOELAB=2018. AGGIORNAMENTO PAGOPA_T_ELABORAZIONE IN STATO=ELABORATO_SCARTATO. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC.
ELABORAZIONE PAGOPA PER FILE_PAGOPA_ID=34.AGGIORNAMENTO SIAC_T_FILE_PAGOPA PER ELABORAZIONE IN CORSO. AGGIORNAMENTO PER ERR.=36.CHIUSURA - CHIUSURA - CHIUSURA - ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=110 ANNOBILANCIOELAB=2018. AGGIORNAMENTO PAGOPA_T_ELABORAZIONE IN STATO=ELABORATO_SCARTATO. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC. AGGIORNAMENTO SIAC_T_FILE_PAGOPA IN STATO=ELABORATO_IN_CORSO_SC.
select *
from pagopa_d_riconciliazione_errore errore
where errore.ente_proprietario_id=2

select *
from pagopa_t_riconciliazione ric
where ric.file_pagopa_id in (32,34,12)

select ric.pagopa_ric_errore_id, *
from pagopa_t_riconciliazione_doc ric
where ric.file_pagopa_id in (32,34,12)
order by ric.pagopa_ric_doc_id desc
-- 116009, 116010, 116011





select ric.*
   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,pagopa_t_riconciliazione ric
   where flusso.pagopa_elab_id=115
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| 115::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=115 --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id
   and   ric.file_pagopa_id =34

select *
from siac_r_subdoc_prov_cassa rsub
where rsub.subdoc_id in (116009, 116010, 116011)

select bil.bil_id, per.periodo_id , fase.fase_operativa_code
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=2
     and   per.anno::integer=2018
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
--     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);

select *
from pagopa_t_elaborazione_log log
where log.ente_proprietario_id=2
order by log.pagopa_elab_log_id desc


select stato.pagopa_elab_stato_code,
      pago.*
from pagopa_t_elaborazione pago,pagopa_d_elaborazione_stato stato
where pago.ente_proprietario_id=2
and   stato.pagopa_elab_stato_id=pago.pagopa_elab_stato_id
CHIUSURA - ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=118 ANNOBILANCIOELAB=2018. AGGIORNAMENTO PAGOPA_T_ELABORAZIONE IN STATO=ELABORATO_SCARTATO.
AGGIORNAMENTO ELABORAZIONE SU FILE file_pagopa_id=34 IN STATO ELABORATO_IN_CORSO


select *
from pagopa_t_riconciliazione ric
where ric.file_pagopa_id in (32,34,12)


-- 32.234,5
insert into pagopa_t_riconciliazione_det
(
  pagopa_det_anag_cognome,
  pagopa_det_anag_nome,
  pagopa_det_anag_ragione_sociale,
  pagopa_det_anag_codice_fiscale,
  pagopa_det_anag_indirizzo,
  pagopa_det_anag_civico,
  pagopa_det_anag_cap,
  pagopa_det_anag_localita,
  pagopa_det_anag_provincia,
  pagopa_det_anag_nazione,
  pagopa_det_anag_email,
  pagopa_det_causale_versamento_desc,
  pagopa_det_causale,
  pagopa_det_data_pagamento,
  pagopa_det_importo_versamento,
  pagopa_ric_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione

)
select  'ROTA',
        'FRANCA',
        'ROTA FRANCA',
        'RTOFNC53A64A182G',
        'Via Duino',
	    '15',
        '10100',
	    'Torino',
	    'TO',
	    'Italia',
	    null,
        'Pagamento Rota Franca',
        'Pagamento Rota Franca',
        ric.pagopa_ric_flusso_data,
        2234.5,
        ric.pagopa_ric_id,
        now(),
        2,
        'test_pagopa'


from pagopa_t_riconciliazione ric
where ric.file_pagopa_id in (32)--,34)
insert into pagopa_t_riconciliazione_det
(
  pagopa_det_anag_cognome,
  pagopa_det_anag_nome,
  pagopa_det_anag_ragione_sociale,
  pagopa_det_anag_codice_fiscale,
  pagopa_det_anag_indirizzo,
  pagopa_det_anag_civico,
  pagopa_det_anag_cap,
  pagopa_det_anag_localita,
  pagopa_det_anag_provincia,
  pagopa_det_anag_nazione,
  pagopa_det_anag_email,
  pagopa_det_causale_versamento_desc,
  pagopa_det_causale,
  pagopa_det_data_pagamento,
  pagopa_det_importo_versamento,
  pagopa_ric_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione

)
select  'ROTA',
        'MARIA VITTORIA',
        'ROTA MARIA VITTORIA',
        'RTOMVT32E58L203O',
        'Via Duino',
	    '15',
        '10100',
	    'Torino',
	    'TO',
	    'Italia',
	    null,
        'Pagamento Rota MARIA VITTORIA',
        'Pagamento Rota MARIA VITTORIA',
        ric.pagopa_ric_flusso_data,
        30000,
        ric.pagopa_ric_id,
        now(),
        2,
        'test_pagopa'
from pagopa_t_riconciliazione ric
where ric.file_pagopa_id in (32)--,34)

insert into pagopa_t_riconciliazione_det
(
  pagopa_det_anag_cognome,
  pagopa_det_anag_nome,
  pagopa_det_anag_ragione_sociale,
  pagopa_det_anag_codice_fiscale,
  pagopa_det_anag_indirizzo,
  pagopa_det_anag_civico,
  pagopa_det_anag_cap,
  pagopa_det_anag_localita,
  pagopa_det_anag_provincia,
  pagopa_det_anag_nazione,
  pagopa_det_anag_email,
  pagopa_det_causale_versamento_desc,
  pagopa_det_causale,
  pagopa_det_data_pagamento,
  pagopa_det_importo_versamento,
  pagopa_ric_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione

)
select  'ROTARIU',
        'CRISTINA',
        'ROTARIU CRISTINA',
        'RTRCST82C59Z140U',
        'Via Duino',
	    '22',
        '10100',
	    'Torino',
	    'TO',
	    'Italia',
	    null,
        'Pagamento ROTARIU CRISTINA',
        'Pagamento ROTARIU CRISTINA',
        ric.pagopa_ric_flusso_data,
        1,
        ric.pagopa_ric_id,
        now(),
        2,
        'test_pagopa'
from pagopa_t_riconciliazione ric
where ric.file_pagopa_id in (34)--,34)

select *
from pagopa_t_riconciliazione_det

select *
from siac_t_soggetto sog
where sog.ente_proprietario_id=2
and   sog.soggetto_code='306630'

select  pago.*
from siac_t_file_pagopa pago
where pago.ente_proprietario_id=2
order by pago.file_pagopa_id

begin;
update siac_t_file_pagopa pago
set    file_pagopa_errore_id=null,
       file_pagopa_note=null,
       file_pagopa_stato_id=2
where pago.file_pagopa_id in (32,34)
update siac_t_file_pagopa pago
set    file_pagopa_errore_id=null,
       file_pagopa_note=null,
       file_pagopa_stato_id=2
where pago.file_pagopa_id in (12)

update pagopa_t_riconciliazione ric
set    pagopa_ric_errore_id=null,
       pagopa_ric_flusso_stato_elab='N'
where ric.file_pagopa_id in (32,34)

update pagopa_t_riconciliazione ric
set    pagopa_ric_errore_id=null,
       pagopa_ric_flusso_stato_elab='N'
where ric.file_pagopa_id in (12)


select stato.file_pagopa_stato_code, pago.*
from siac_t_file_pagopa pago,siac_d_file_pagopa_stato stato
where pago.ente_proprietario_id=2
and   stato.file_pagopa_stato_id=pago.file_pagopa_stato_id
--and   pago.data_cancellazione is null
--and   pago.validita_fine is null
order by pago.file_pagopa_id
ELABORAZIONE PAGOPA PER FILE_PAGOPA_ID=32.AGGIORNAMENTO SIAC_T_FILE_PAGOPA PER ELABORAZIONE IN CORSO.
ELABORAZIONE PAGOPA PER FILE_PAGOPA_ID=32.VERIFICA ESISTENZA TIPO DOCUMENTO=COR. IDENTIFICATIVO INSESISTENTE.

select p.*
from siac_t_prov_cassa p
where p.ente_proprietario_id=2
and   p.provc_anno::integer=2018
and   p.provc_numero::integer=8715
-- provc_id=47125

select *
from siac_r_subdoc_prov_cassa rsub
where rsub.provc_id in (46948)

select *
from siac_r_ordinativo_prov_cassa rsub
where rsub.provc_id in (46948)

begin;
update siac_r_subdoc_prov_cassa rsub
set    data_cancellazione=now()
where rsub.provc_id in (46948)
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null

select ts.*
from siac_v_bko_accertamento_valido acc,siac_t_movgest_ts ts
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=10
and  ts.movgest_ts_id=acc.movgest_ts_id

select attr.attr_code, rattr.boolean,rattr.bil_elem_attr_id
from siac_v_bko_accertamento_valido acc,siac_t_movgest_ts ts,
     siac_r_movgest_ts_attr rattr,siac_t_attr attr
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=10
and   ts.movgest_ts_id=acc.movgest_ts_id
and   rattr.movgest_ts_id=acc.movgest_ts_id
and   attr.attr_id=rattr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
-- 1580483
select * from siac_r_movgest_ts_attr where bil_elem_attr_id=1580484
begin;
insert into siac_r_movgest_ts_attr
(
	movgest_ts_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select acc.movgest_ts_id,
       attr.attr_id,
       'S',
       now(),
       'test_pago_pa',
       attr.ente_proprietario_id
from siac_v_bko_accertamento_valido acc,siac_t_attr attr
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=10
and   attr.ente_proprietario_id=2
and   attr.attr_code='FlagCollegamentoAccertamentoFattura'


insert into siac_r_movgest_ts_attr
(
	movgest_ts_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select acc.movgest_ts_id,
       attr.attr_id,
       'S',
       now(),
       'test_pago_pa',
       attr.ente_proprietario_id
from siac_v_bko_accertamento_valido acc,siac_t_attr attr
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=10
and   attr.ente_proprietario_id=2
and   attr.attr_code='FlagCollegamentoAccertamentoCorrispettivo'

select *
from siac_t_Attr attr
where attr.ente_proprietario_id=2
and   attr.attr_code='FlagCollegamentoAccertamentoCorrispettivo'


insert into siac_r_movgest_ts_attr
(
	movgest_ts_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select acc.movgest_ts_id,
       attr.attr_id,
       'S',
       now(),
       'test_pago_pa',
       attr.ente_proprietario_id
from siac_v_bko_accertamento_valido acc,siac_t_attr attr
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=15
and   attr.ente_proprietario_id=2
and   attr.attr_code='FlagCollegamentoAccertamentoFattura'

rollback;
begin;
INSERT INTO
  siac.siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'COR',
       'CORRISPETTIVO',
       a.doc_fam_tipo_id,
       now(),
       a.ente_proprietario_id,
       'SIAC-6720'
 from siac_d_doc_fam_tipo a
 where  a.ente_proprietario_id=2
 and    a.doc_fam_tipo_code='E'
 and not exists (select 1 from siac_d_doc_tipo z where z.doc_tipo_code='COR' AND
 z.ente_proprietario_id=a.ente_proprietario_id
  );

INSERT INTO
  siac.siac_r_doc_tipo_attr
(
  doc_tipo_id,
  attr_id,
  "boolean",
  tabella_id,
  numerico,
  percentuale,
  testo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipoCor.doc_tipo_id,
       rattr.attr_id,
       rattr.boolean,
       rattr.tabella_id,
       rattr.numerico,
       rattr.percentuale,
       rattr.testo,
       now(),
       rattr.ente_proprietario_id,
       'SIAC-6720'
from siac_d_doc_tipo tipoFtv,siac_r_doc_tipo_attr rattr,siac_d_doc_tipo tipoCor ,siac_d_doc_fam_tipo fam
where fam.ente_proprietario_id=2
and   fam.doc_fam_tipo_code='E'
and   tipoFtv.doc_fam_tipo_id=fam.doc_fam_tipo_id
and   tipoFtv.doc_tipo_code='FTV'
and   tipoCor.doc_fam_tipo_id=fam.doc_fam_tipo_id
and   tipoCor.doc_tipo_code='COR'
and   rattr.doc_tipo_id=tipoFtv.doc_tipo_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null

rollback;
begin;
update siac_t_movgest_ts ts
set    movgest_ts_prev_fatt=false,
       movgest_ts_prev_cor=false
from siac_v_bko_accertamento_valido acc
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=10
and  ts.movgest_ts_id=acc.movgest_ts_id;


select fam.doc_fam_tipo_code, tipo.*
from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code='COR'
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
-- E
select fam.doc_fam_tipo_code, gruppo.doc_gruppo_tipo_code, tipo.*
from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam,siac_d_doc_gruppo gruppo
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code='FTV'
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   gruppo.doc_gruppo_tipo_id=tipo.doc_gruppo_tipo_id


rollback;
begin;
select *
from fnc_pagopa_t_elaborazione_riconc
(
  2,--enteproprietarioid integer,
  'test_pagopa_2019',--loginoperazione varchar,
  now()::timestamp--dataelaborazione timestamp
);
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=161 ANNOBILANCIOELAB=2018.GESTIONE SCARTI DI ELABORAZIONE. LETTURA PROGRESSIVO DOC. SIAC_T_DOC_NUM [FTV-COR] PER ANNO=2018.ERRORE DB:42703 COLUMN "DOCTIPOFATRID" DOES NOT EXIST
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=151 ANNOBILANCIOELAB=2018.INSERIMENTO DOCUMENTO PER SOGGETTO=108297. VOCE BOLLO. STRUTTURA AMMINISTRATIVA   [SIAC_T_DOC].ERRORE DB:42703 RECORD "PAGOPAFLUSSOREC" HAS NO FIELD "PAGOPA_DOC_TIPO"
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=153 ANNOBILANCIOELAB=2018.GESTIONE SCARTI DI ELABORAZIONE. LETTURA PROGRESSIVO DOC. SIAC_T_DOC_NUM [FTV-COR] PER ANNO=2018.ERRORE DB:23502 NULL VALUE IN COLUMN "DOC_TIPO_ID" VIOLATES NOT-NULL CONSTRAINT
select
       sub.*
from siac_t_subdoc sub,siac_t_doc doc, siac_d_doc_tipo tipo, pagopa_t_riconciliazione_doc ric
where sub.ente_proprietario_id=2
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   ric.file_pagopa_id >=8
and   ric.pagopa_ric_doc_subdoc_id=sub.subdoc_id

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
where  flusso.pagopa_elab_id=175
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


select *
from pagopa_t_modifica_elab

select *
from siac_t_subdoc sub
where sub.doc_id=78390


select *
from siac_t_subdoc sub,siac_r_subdoc_atto_amm r
where sub.doc_id=78390
and   r.subdoc_id=sub.subdoc_id

-- select 80000-64469=15531

select mdet.movgest_ts_det_importo, stato.mod_stato_code,acc.movgest_anno, acc.movgest_numero,
       detacc.movgest_ts_det_importo, detacc.login_operazione,
       elab.*
from pagopa_t_modifica_elab elab, siac_t_modifica mod,siac_r_modifica_Stato rs,siac_d_modifica_Stato stato,
     siac_t_movgest_ts_Det_mod mdet,siac_v_bko_accertamento_valido acc,siac_t_movgest_ts_det detacc
where elab.pagopa_elab_id=149
and   mod.mod_id=elab.mod_id
and   rs.mod_id=mod.mod_id
and   stato.mod_stato_id=rs.mod_stato_id
and   mdet.mod_stato_r_id=rs.mod_stato_r_id
and   acc.movgest_ts_id=mdet.movgest_ts_id
and   detacc.movgest_ts_det_id=mdet.movgest_ts_det_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

select *
from siac_t_attr attr
where attr.ente_proprietario_id=2
and   attr.attr_code = 'flagSenzaNumero'

select fam.doc_fam_tipo_code,tipo.doc_tipo_code,attr.attr_code,r.boolean,r.doc_tipo_attr_id, tipo.*
from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam,siac_r_doc_tipo_attr r,siac_t_attr attr
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code in ('COR','FTV','IPA')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'
and   r.doc_tipo_id=tipo.doc_tipo_id
and   attr.attr_id=r.attr_id
and   r.data_cancellazione is null
and   r.validita_fine  is null

select * from siac_r_doc_tipo_attr r where r.doc_tipo_attr_id=3258

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
       'admin',
       tipo.ente_proprietario_id
from siac_d_attr_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.attr_tipo_code='B'

-- provare inserire attributi per numeroAutomatico
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
       'test_pagopa',
       attr.ente_proprietario_id
from siac_t_attr attr,   siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where attr.ente_proprietario_id=2
and   attr.attr_code='flagSenzaNumero'
and   tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code in ('COR','FTV')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'


select tipo.doc_tipo_code, num.*
from siac_t_doc_num num,siac_d_doc_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_id=num.doc_tipo_id




update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id--,
--                data_modifica=clock_timestamp(),
--                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     		/*and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;


-- ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST

select *
from siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2

ACQUISITO
ELABORATO_IN_CORSO
ELABORATO_IN_CORSO_SC
ELABORATO_IN_CORSO_ERgest_ts_id,
       attr.attr_id,
       'S',
       now(),
       'test_pago_pa',
       attr.ente_proprietario_id
from siac_v_bko_accertamento_valido acc,siac_t_attr attr
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=15
and   attr.ente_proprietario_id=2
and   attr.attr_code='FlagCollegamentoAccertamentoFattura'

rollback;
begin;
INSERT INTO
  siac.siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'COR',
       'CORRISPETTIVO',
       a.doc_fam_tipo_id,
       now(),
       a.ente_proprietario_id,
       'SIAC-6720'
 from siac_d_doc_fam_tipo a
 where  a.ente_proprietario_id=2
 and    a.doc_fam_tipo_code='E'
 and not exists (select 1 from siac_d_doc_tipo z where z.doc_tipo_code='COR' AND
 z.ente_proprietario_id=a.ente_proprietario_id
  );

INSERT INTO
  siac.siac_r_doc_tipo_attr
(
  doc_tipo_id,
  attr_id,
  "boolean",
  tabella_id,
  numerico,
  percentuale,
  testo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipoCor.doc_tipo_id,
       rattr.attr_id,
       rattr.boolean,
       rattr.tabella_id,
       rattr.numerico,
       rattr.percentuale,
       rattr.testo,
       now(),
       rattr.ente_proprietario_id,
       'SIAC-6720'
from siac_d_doc_tipo tipoFtv,siac_r_doc_tipo_attr rattr,siac_d_doc_tipo tipoCor ,siac_d_doc_fam_tipo fam
where fam.ente_proprietario_id=2
and   fam.doc_fam_tipo_code='E'
and   tipoFtv.doc_fam_tipo_id=fam.doc_fam_tipo_id
and   tipoFtv.doc_tipo_code='FTV'
and   tipoCor.doc_fam_tipo_id=fam.doc_fam_tipo_id
and   tipoCor.doc_tipo_code='COR'
and   rattr.doc_tipo_id=tipoFtv.doc_tipo_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null

rollback;
begin;
update siac_t_movgest_ts ts
set    movgest_ts_prev_fatt=false,
       movgest_ts_prev_cor=false
from siac_v_bko_accertamento_valido acc
where acc.ente_proprietario_id=2
and   acc.anno_bilancio=2018
and   acc.movgest_anno=2018
and   acc.movgest_numero=10
and  ts.movgest_ts_id=acc.movgest_ts_id;


select fam.doc_fam_tipo_code, tipo.*
from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code='COR'
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
-- E
select fam.doc_fam_tipo_code, gruppo.doc_gruppo_tipo_code, tipo.*
from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam,siac_d_doc_gruppo gruppo
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code='FTV'
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   gruppo.doc_gruppo_tipo_id=tipo.doc_gruppo_tipo_id


rollback;
begin;
select *
from fnc_pagopa_t_elaborazione_riconc
(
  2,--enteproprietarioid integer,
  'test_pagopa_2019',--loginoperazione varchar,
  now()::timestamp--dataelaborazione timestamp
);
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=161 ANNOBILANCIOELAB=2018.GESTIONE SCARTI DI ELABORAZIONE. LETTURA PROGRESSIVO DOC. SIAC_T_DOC_NUM [FTV-COR] PER ANNO=2018.ERRORE DB:42703 COLUMN "DOCTIPOFATRID" DOES NOT EXIST
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=151 ANNOBILANCIOELAB=2018.INSERIMENTO DOCUMENTO PER SOGGETTO=108297. VOCE BOLLO. STRUTTURA AMMINISTRATIVA   [SIAC_T_DOC].ERRORE DB:42703 RECORD "PAGOPAFLUSSOREC" HAS NO FIELD "PAGOPA_DOC_TIPO"
ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=153 ANNOBILANCIOELAB=2018.GESTIONE SCARTI DI ELABORAZIONE. LETTURA PROGRESSIVO DOC. SIAC_T_DOC_NUM [FTV-COR] PER ANNO=2018.ERRORE DB:23502 NULL VALUE IN COLUMN "DOC_TIPO_ID" VIOLATES NOT-NULL CONSTRAINT
select
       sub.*
from siac_t_subdoc sub,siac_t_doc doc, siac_d_doc_tipo tipo, pagopa_t_riconciliazione_doc ric
where sub.ente_proprietario_id=2
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   ric.file_pagopa_id >=8
and   ric.pagopa_ric_doc_subdoc_id=sub.subdoc_id

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
where  flusso.pagopa_elab_id=175
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


select *
from pagopa_t_modifica_elab

select *
from siac_t_subdoc sub
where sub.doc_id=78390


select *
from siac_t_subdoc sub,siac_r_subdoc_atto_amm r
where sub.doc_id=78390
and   r.subdoc_id=sub.subdoc_id

-- select 80000-64469=15531

select mdet.movgest_ts_det_importo, stato.mod_stato_code,acc.movgest_anno, acc.movgest_numero,
       detacc.movgest_ts_det_importo, detacc.login_operazione,
       elab.*
from pagopa_t_modifica_elab elab, siac_t_modifica mod,siac_r_modifica_Stato rs,siac_d_modifica_Stato stato,
     siac_t_movgest_ts_Det_mod mdet,siac_v_bko_accertamento_valido acc,siac_t_movgest_ts_det detacc
where elab.pagopa_elab_id=149
and   mod.mod_id=elab.mod_id
and   rs.mod_id=mod.mod_id
and   stato.mod_stato_id=rs.mod_stato_id
and   mdet.mod_stato_r_id=rs.mod_stato_r_id
and   acc.movgest_ts_id=mdet.movgest_ts_id
and   detacc.movgest_ts_det_id=mdet.movgest_ts_det_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

select *
from siac_t_attr attr
where attr.ente_proprietario_id=2
and   attr.attr_code = 'flagSenzaNumero'

select fam.doc_fam_tipo_code,tipo.doc_tipo_code,attr.attr_code,r.boolean,r.doc_tipo_attr_id, tipo.*
from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam,siac_r_doc_tipo_attr r,siac_t_attr attr
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code in ('COR','FTV','IPA')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'
and   r.doc_tipo_id=tipo.doc_tipo_id
and   attr.attr_id=r.attr_id
and   r.data_cancellazione is null
and   r.validita_fine  is null

select * from siac_r_doc_tipo_attr r where r.doc_tipo_attr_id=3258

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
       'admin',
       tipo.ente_proprietario_id
from siac_d_attr_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.attr_tipo_code='B'

-- provare inserire attributi per numeroAutomatico
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
       'test_pagopa',
       attr.ente_proprietario_id
from siac_t_attr attr,   siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where attr.ente_proprietario_id=2
and   attr.attr_code='flagSenzaNumero'
and   tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code in ('COR','FTV')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'


select tipo.doc_tipo_code, num.*
from siac_t_doc_num num,siac_d_doc_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_id=num.doc_tipo_id




update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id--,
--                data_modifica=clock_timestamp(),
--                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     		/*and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;


-- ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST

select *
from siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2

ACQUISITO
ELABORATO_IN_CORSO
ELABORATO_IN_CORSO_SC
ELABORATO_IN_CORSO_ER