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
ELABORATO_IN_CORSO_ER g e s t _ t s _ i d , 
 
               a t t r . a t t r _ i d , 
 
               ' S ' , 
 
               n o w ( ) , 
 
               ' t e s t _ p a g o _ p a ' , 
 
               a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
 f r o m   s i a c _ v _ b k o _ a c c e r t a m e n t o _ v a l i d o   a c c , s i a c _ t _ a t t r   a t t r 
 
 w h e r e   a c c . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       a c c . a n n o _ b i l a n c i o = 2 0 1 8 
 
 a n d       a c c . m o v g e s t _ a n n o = 2 0 1 8 
 
 a n d       a c c . m o v g e s t _ n u m e r o = 1 5 
 
 a n d       a t t r . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       a t t r . a t t r _ c o d e = ' F l a g C o l l e g a m e n t o A c c e r t a m e n t o F a t t u r a ' 
 
 
 
 r o l l b a c k ; 
 
 b e g i n ; 
 
 I N S E R T   I N T O 
 
     s i a c . s i a c _ d _ d o c _ t i p o 
 
 ( 
 
     d o c _ t i p o _ c o d e , 
 
     d o c _ t i p o _ d e s c , 
 
     d o c _ f a m _ t i p o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' C O R ' , 
 
               ' C O R R I S P E T T I V O ' , 
 
               a . d o c _ f a m _ t i p o _ i d , 
 
               n o w ( ) , 
 
               a . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' S I A C - 6 7 2 0 ' 
 
   f r o m   s i a c _ d _ d o c _ f a m _ t i p o   a 
 
   w h e r e     a . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
   a n d         a . d o c _ f a m _ t i p o _ c o d e = ' E ' 
 
   a n d   n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ d _ d o c _ t i p o   z   w h e r e   z . d o c _ t i p o _ c o d e = ' C O R '   A N D 
 
   z . e n t e _ p r o p r i e t a r i o _ i d = a . e n t e _ p r o p r i e t a r i o _ i d 
 
     ) ; 
 
 
 
 I N S E R T   I N T O 
 
     s i a c . s i a c _ r _ d o c _ t i p o _ a t t r 
 
 ( 
 
     d o c _ t i p o _ i d , 
 
     a t t r _ i d , 
 
     " b o o l e a n " , 
 
     t a b e l l a _ i d , 
 
     n u m e r i c o , 
 
     p e r c e n t u a l e , 
 
     t e s t o , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o C o r . d o c _ t i p o _ i d , 
 
               r a t t r . a t t r _ i d , 
 
               r a t t r . b o o l e a n , 
 
               r a t t r . t a b e l l a _ i d , 
 
               r a t t r . n u m e r i c o , 
 
               r a t t r . p e r c e n t u a l e , 
 
               r a t t r . t e s t o , 
 
               n o w ( ) , 
 
               r a t t r . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' S I A C - 6 7 2 0 ' 
 
 f r o m   s i a c _ d _ d o c _ t i p o   t i p o F t v , s i a c _ r _ d o c _ t i p o _ a t t r   r a t t r , s i a c _ d _ d o c _ t i p o   t i p o C o r   , s i a c _ d _ d o c _ f a m _ t i p o   f a m 
 
 w h e r e   f a m . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       f a m . d o c _ f a m _ t i p o _ c o d e = ' E ' 
 
 a n d       t i p o F t v . d o c _ f a m _ t i p o _ i d = f a m . d o c _ f a m _ t i p o _ i d 
 
 a n d       t i p o F t v . d o c _ t i p o _ c o d e = ' F T V ' 
 
 a n d       t i p o C o r . d o c _ f a m _ t i p o _ i d = f a m . d o c _ f a m _ t i p o _ i d 
 
 a n d       t i p o C o r . d o c _ t i p o _ c o d e = ' C O R ' 
 
 a n d       r a t t r . d o c _ t i p o _ i d = t i p o F t v . d o c _ t i p o _ i d 
 
 a n d       r a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r a t t r . v a l i d i t a _ f i n e   i s   n u l l 
 
 
 
 r o l l b a c k ; 
 
 b e g i n ; 
 
 u p d a t e   s i a c _ t _ m o v g e s t _ t s   t s 
 
 s e t         m o v g e s t _ t s _ p r e v _ f a t t = f a l s e , 
 
               m o v g e s t _ t s _ p r e v _ c o r = f a l s e 
 
 f r o m   s i a c _ v _ b k o _ a c c e r t a m e n t o _ v a l i d o   a c c 
 
 w h e r e   a c c . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       a c c . a n n o _ b i l a n c i o = 2 0 1 8 
 
 a n d       a c c . m o v g e s t _ a n n o = 2 0 1 8 
 
 a n d       a c c . m o v g e s t _ n u m e r o = 1 0 
 
 a n d     t s . m o v g e s t _ t s _ i d = a c c . m o v g e s t _ t s _ i d ; 
 
 
 
 
 
 s e l e c t   f a m . d o c _ f a m _ t i p o _ c o d e ,   t i p o . * 
 
 f r o m   s i a c _ d _ d o c _ t i p o   t i p o , s i a c _ d _ d o c _ f a m _ t i p o   f a m 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       t i p o . d o c _ t i p o _ c o d e = ' C O R ' 
 
 a n d       f a m . d o c _ f a m _ t i p o _ i d = t i p o . d o c _ f a m _ t i p o _ i d 
 
 - -   E 
 
 s e l e c t   f a m . d o c _ f a m _ t i p o _ c o d e ,   g r u p p o . d o c _ g r u p p o _ t i p o _ c o d e ,   t i p o . * 
 
 f r o m   s i a c _ d _ d o c _ t i p o   t i p o , s i a c _ d _ d o c _ f a m _ t i p o   f a m , s i a c _ d _ d o c _ g r u p p o   g r u p p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       t i p o . d o c _ t i p o _ c o d e = ' F T V ' 
 
 a n d       f a m . d o c _ f a m _ t i p o _ i d = t i p o . d o c _ f a m _ t i p o _ i d 
 
 a n d       g r u p p o . d o c _ g r u p p o _ t i p o _ i d = t i p o . d o c _ g r u p p o _ t i p o _ i d 
 
 
 
 
 
 r o l l b a c k ; 
 
 b e g i n ; 
 
 s e l e c t   * 
 
 f r o m   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c 
 
 ( 
 
     2 , - - e n t e p r o p r i e t a r i o i d   i n t e g e r , 
 
     ' t e s t _ p a g o p a _ 2 0 1 9 ' , - - l o g i n o p e r a z i o n e   v a r c h a r , 
 
     n o w ( ) : : t i m e s t a m p - - d a t a e l a b o r a z i o n e   t i m e s t a m p 
 
 ) ; 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 1 6 1   A N N O B I L A N C I O E L A B = 2 0 1 8 . G E S T I O N E   S C A R T I   D I   E L A B O R A Z I O N E .   L E T T U R A   P R O G R E S S I V O   D O C .   S I A C _ T _ D O C _ N U M   [ F T V - C O R ]   P E R   A N N O = 2 0 1 8 . E R R O R E   D B : 4 2 7 0 3   C O L U M N   " D O C T I P O F A T R I D "   D O E S   N O T   E X I S T 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 1 5 1   A N N O B I L A N C I O E L A B = 2 0 1 8 . I N S E R I M E N T O   D O C U M E N T O   P E R   S O G G E T T O = 1 0 8 2 9 7 .   V O C E   B O L L O .   S T R U T T U R A   A M M I N I S T R A T I V A       [ S I A C _ T _ D O C ] . E R R O R E   D B : 4 2 7 0 3   R E C O R D   " P A G O P A F L U S S O R E C "   H A S   N O   F I E L D   " P A G O P A _ D O C _ T I P O " 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 1 5 3   A N N O B I L A N C I O E L A B = 2 0 1 8 . G E S T I O N E   S C A R T I   D I   E L A B O R A Z I O N E .   L E T T U R A   P R O G R E S S I V O   D O C .   S I A C _ T _ D O C _ N U M   [ F T V - C O R ]   P E R   A N N O = 2 0 1 8 . E R R O R E   D B : 2 3 5 0 2   N U L L   V A L U E   I N   C O L U M N   " D O C _ T I P O _ I D "   V I O L A T E S   N O T - N U L L   C O N S T R A I N T 
 
 s e l e c t 
 
               s u b . * 
 
 f r o m   s i a c _ t _ s u b d o c   s u b , s i a c _ t _ d o c   d o c ,   s i a c _ d _ d o c _ t i p o   t i p o ,   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   r i c 
 
 w h e r e   s u b . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       d o c . d o c _ i d = s u b . d o c _ i d 
 
 a n d       t i p o . d o c _ t i p o _ i d = d o c . d o c _ t i p o _ i d 
 
 a n d       r i c . f i l e _ p a g o p a _ i d   > = 8 
 
 a n d       r i c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d = s u b . s u b d o c _ i d 
 
 
 
 s e l e c t   t i p o d . d o c _ t i p o _ c o d e , 
 
               s o g . s o g g e t t o _ c o d e ,   s o g . s o g g e t t o _ d e s c , 
 
               d o c u . d o c _ a n n o , 
 
               d o c u . d o c _ n u m e r o , 
 
               d o c u . d o c _ d e s c , 
 
               d o c u . d o c _ i m p o r t o , 
 
               d o c u . d o c _ d a t a _ e m i s s i o n e , 
 
               d o c u . d o c _ d a t a _ s c a d e n z a , 
 
               s u b . s u b d o c _ d a t a _ s c a d e n z a , 
 
               s u b . s u b d o c _ n u m e r o , 
 
               s u b . s u b d o c _ d e s c , 
 
               d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e , 
 
               d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , 
 
               d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e , 
 
               d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , 
 
               s u b . s u b d o c _ i m p o r t o , 
 
               d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ i m p o r t o , 
 
               d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
               d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
               a c c . m o v g e s t _ a n n o , 
 
               a c c . m o v g e s t _ n u m e r o , 
 
               f l u s s o . p a g o p a _ e l a b _ f l u s s o _ a n n o _ p r o v v i s o r i o , 
 
               f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n u m _ p r o v v i s o r i o , 
 
               p r o v . p r o v c _ a n n o , 
 
               p r o v . p r o v c _ n u m e r o , 
 
               d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , 
 
               c . c l a s s i f _ c o d e , 
 
               d o c u . d o c _ i d 
 
 
 
 f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c ,   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c , p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , 
 
             s i a c _ t _ s u b d o c   s u b   ,   s i a c _ r _ d o c _ s o g   r s o g ,   s i a c _ t _ s o g g e t t o   s o g , 
 
             s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r s u b ,   s i a c _ v _ b k o _ a c c e r t a m e n t o _ v a l i d o   a c c , 
 
             s i a c _ r _ s u b d o c _ p r o v _ c a s s a   r p r o v ,   s i a c _ t _ p r o v _ c a s s a   p r o v , s i a c _ d _ d o c _ t i p o   t i p o d , 
 
             s i a c _ t _ d o c   d o c u   l e f t   j o i n   s i a c _ r _ d o c _ c l a s s   r c   j o i n   s i a c _ t _ c l a s s   c   j o i n   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                                                                                                                                                             o n   (   t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d   a n d   t i p o . c l a s s i f _ t i p o _ c o d e   i n   ( ' C D C ' , ' C D R ' )   ) 
 
                                                                                                                   o n   ( r c . c l a s s i f _ i d = c . c l a s s i f _ i d   ) 
 
             o n   (   r c . d o c _ i d = d o c u . d o c _ i d ) 
 
 w h e r e     f l u s s o . p a g o p a _ e l a b _ i d = 1 7 5 
 
 a n d         d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 a n d         r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
 a n d         s u b . s u b d o c _ i d = d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d 
 
 a n d         d o c u . d o c _ i d = s u b . d o c _ i d 
 
 a n d         r s o g . d o c _ i d = d o c u . d o c _ i d 
 
 a n d         s o g . s o g g e t t o _ i d = r s o g . s o g g e t t o _ i d 
 
 a n d         r s u b . s u b d o c _ i d = s u b . s u b d o c _ i d 
 
 a n d         a c c . m o v g e s t _ t s _ i d = r s u b . m o v g e s t _ t s _ i d 
 
 a n d         r p r o v . s u b d o c _ i d = s u b . s u b d o c _ i d 
 
 a n d         p r o v . p r o v c _ i d = r p r o v . p r o v c _ i d 
 
 a n d         p r o v . p r o v c _ i d = d o c . p a g o p a _ r i c _ d o c _ p r o v c _ i d 
 
 a n d         t i p o d . d o c _ t i p o _ i d = d o c u . d o c _ t i p o _ i d 
 
 - - a n d         t i p o d . d o c _ t i p o _ c o d e = ' I P A ' 
 
 o r d e r   b y   d o c u . d o c _ i d , s u b . s u b d o c _ i d 
 
 
 
 
 
 s e l e c t   * 
 
 f r o m   p a g o p a _ t _ m o d i f i c a _ e l a b 
 
 
 
 s e l e c t   * 
 
 f r o m   s i a c _ t _ s u b d o c   s u b 
 
 w h e r e   s u b . d o c _ i d = 7 8 3 9 0 
 
 
 
 
 
 s e l e c t   * 
 
 f r o m   s i a c _ t _ s u b d o c   s u b , s i a c _ r _ s u b d o c _ a t t o _ a m m   r 
 
 w h e r e   s u b . d o c _ i d = 7 8 3 9 0 
 
 a n d       r . s u b d o c _ i d = s u b . s u b d o c _ i d 
 
 
 
 - -   s e l e c t   8 0 0 0 0 - 6 4 4 6 9 = 1 5 5 3 1 
 
 
 
 s e l e c t   m d e t . m o v g e s t _ t s _ d e t _ i m p o r t o ,   s t a t o . m o d _ s t a t o _ c o d e , a c c . m o v g e s t _ a n n o ,   a c c . m o v g e s t _ n u m e r o , 
 
               d e t a c c . m o v g e s t _ t s _ d e t _ i m p o r t o ,   d e t a c c . l o g i n _ o p e r a z i o n e , 
 
               e l a b . * 
 
 f r o m   p a g o p a _ t _ m o d i f i c a _ e l a b   e l a b ,   s i a c _ t _ m o d i f i c a   m o d , s i a c _ r _ m o d i f i c a _ S t a t o   r s , s i a c _ d _ m o d i f i c a _ S t a t o   s t a t o , 
 
           s i a c _ t _ m o v g e s t _ t s _ D e t _ m o d   m d e t , s i a c _ v _ b k o _ a c c e r t a m e n t o _ v a l i d o   a c c , s i a c _ t _ m o v g e s t _ t s _ d e t   d e t a c c 
 
 w h e r e   e l a b . p a g o p a _ e l a b _ i d = 1 4 9 
 
 a n d       m o d . m o d _ i d = e l a b . m o d _ i d 
 
 a n d       r s . m o d _ i d = m o d . m o d _ i d 
 
 a n d       s t a t o . m o d _ s t a t o _ i d = r s . m o d _ s t a t o _ i d 
 
 a n d       m d e t . m o d _ s t a t o _ r _ i d = r s . m o d _ s t a t o _ r _ i d 
 
 a n d       a c c . m o v g e s t _ t s _ i d = m d e t . m o v g e s t _ t s _ i d 
 
 a n d       d e t a c c . m o v g e s t _ t s _ d e t _ i d = m d e t . m o v g e s t _ t s _ d e t _ i d 
 
 a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
 
 
 s e l e c t   * 
 
 f r o m   s i a c _ t _ a t t r   a t t r 
 
 w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       a t t r . a t t r _ c o d e   =   ' f l a g S e n z a N u m e r o ' 
 
 
 
 s e l e c t   f a m . d o c _ f a m _ t i p o _ c o d e , t i p o . d o c _ t i p o _ c o d e , a t t r . a t t r _ c o d e , r . b o o l e a n , r . d o c _ t i p o _ a t t r _ i d ,   t i p o . * 
 
 f r o m   s i a c _ d _ d o c _ t i p o   t i p o , s i a c _ d _ d o c _ f a m _ t i p o   f a m , s i a c _ r _ d o c _ t i p o _ a t t r   r , s i a c _ t _ a t t r   a t t r 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       t i p o . d o c _ t i p o _ c o d e   i n   ( ' C O R ' , ' F T V ' , ' I P A ' ) 
 
 a n d       f a m . d o c _ f a m _ t i p o _ i d = t i p o . d o c _ f a m _ t i p o _ i d 
 
 a n d       f a m . d o c _ f a m _ t i p o _ c o d e = ' E ' 
 
 a n d       r . d o c _ t i p o _ i d = t i p o . d o c _ t i p o _ i d 
 
 a n d       a t t r . a t t r _ i d = r . a t t r _ i d 
 
 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r . v a l i d i t a _ f i n e     i s   n u l l 
 
 
 
 s e l e c t   *   f r o m   s i a c _ r _ d o c _ t i p o _ a t t r   r   w h e r e   r . d o c _ t i p o _ a t t r _ i d = 3 2 5 8 
 
 
 
 i n s e r t   i n t o   s i a c _ t _ a t t r 
 
 ( 
 
   a t t r _ c o d e , 
 
   a t t r _ d e s c , 
 
   a t t r _ t i p o _ i d , 
 
   v a l i d i t a _ i n i z i o , 
 
   l o g i n _ o p e r a z i o n e , 
 
   e n t e _ p r o p r i e t a r i o _ i d 
 
 ) 
 
 s e l e c t   ' f l a g S e n z a N u m e r o ' , 
 
               ' f l a g S e n z a N u m e r o ' , 
 
               t i p o . a t t r _ t i p o _ i d , 
 
               n o w ( ) , 
 
               ' a d m i n ' , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
 f r o m   s i a c _ d _ a t t r _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       t i p o . a t t r _ t i p o _ c o d e = ' B ' 
 
 
 
 - -   p r o v a r e   i n s e r i r e   a t t r i b u t i   p e r   n u m e r o A u t o m a t i c o 
 
 i n s e r t   i n t o   s i a c _ r _ d o c _ t i p o _ a t t r 
 
 ( 
 
 	 d o c _ t i p o _ i d , 
 
         a t t r _ i d , 
 
         b o o l e a n , 
 
         v a l i d i t a _ i n i z i o , 
 
         l o g i n _ o p e r a z i o n e , 
 
         e n t e _ p r o p r i e t a r i o _ i d 
 
 ) 
 
 s e l e c t   t i p o . d o c _ t i p o _ i d , 
 
               a t t r . a t t r _ i d , 
 
               ' S ' , 
 
               n o w ( ) , 
 
               ' t e s t _ p a g o p a ' , 
 
               a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
 f r o m   s i a c _ t _ a t t r   a t t r ,       s i a c _ d _ d o c _ t i p o   t i p o , s i a c _ d _ d o c _ f a m _ t i p o   f a m 
 
 w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       a t t r . a t t r _ c o d e = ' f l a g S e n z a N u m e r o ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       t i p o . d o c _ t i p o _ c o d e   i n   ( ' C O R ' , ' F T V ' ) 
 
 a n d       f a m . d o c _ f a m _ t i p o _ i d = t i p o . d o c _ f a m _ t i p o _ i d 
 
 a n d       f a m . d o c _ f a m _ t i p o _ c o d e = ' E ' 
 
 
 
 
 
 s e l e c t   t i p o . d o c _ t i p o _ c o d e ,   n u m . * 
 
 f r o m   s i a c _ t _ d o c _ n u m   n u m , s i a c _ d _ d o c _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       t i p o . d o c _ t i p o _ i d = n u m . d o c _ t i p o _ i d 
 
 
 
 
 
 
 
 
 
 u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e     d o c U P D 
 
                   s e t         p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
     	 	 	         p a g o p a _ r i c _ e r r o r e _ i d = e r r o r e . p a g o p a _ r i c _ e r r o r e _ i d - - , 
 
 - -                                 d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
 - -                                 l o g i n _ o p e r a z i o n e = s p l i t _ p a r t ( d o c U P D . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r ,   1 ) | | ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r 
 
                   f r o m 
 
                   ( 
 
 	 	     w i t h 
 
                     p a g o p a   a s 
 
                     ( 
 
                         s e l e c t     d o c . p a g o p a _ r i c _ d o c _ i d , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f , 
 
                                         d o c . p a g o p a _ r i c _ i d 
 
                     	 f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         w h e r e     f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
       	                 a n d         d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d = p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ i d   - -   3 0 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) ) 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ t e m a t i c a , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) ) 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e = p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) = c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) ) 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ c o d e 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) ) 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ r i c _ f l u s s o _ i d = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ i d 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n o m e _ m i t t e n t e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
         	 	 a n d         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   =   ' N ' 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
 	 	 	 a n d         d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
           	 	 / * a n d       n o t   e x i s t s   - -   t u t t i   r e c o r d   d i   u n   f l u s s o   d a   e l a b o r a r e   e   s e n z a   s c a r t i   o   e r r o r i 
 
       	 	         ( 
 
 	 	           s e l e c t   1 
 
 	 	           f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 1 
 
 	 	           w h e r e   d o c 1 . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 	 	           a n d       d o c 1 . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   n o t   i n   ( ' N ' , ' S ' ) 
 
 	 	           a n d       d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         ) * / 
 
 	 	         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	           	 a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) , 
 
                     a c c e r t a m e n t i   a s 
 
                     ( 
 
                     s e l e c t   t s . m o v g e s t _ t s _ i d ,   r s o g . s o g g e t t o _ i d 
 
                     f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , 
 
                               s i a c _ r _ m o v g e s t _ t s _ s o g   r s o g 
 
                     w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
                     a n d       m o v . m o v g e s t _ t i p o _ i d = m o v g e s t T i p o I d 
 
                     a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                     a n d       t s . m o v g e s t _ t s _ t i p o _ i d = m o v g e s t T s T i p o I d 
 
                     a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       r s . m o v g e s t _ s t a t o _ i d = m o v g e s t S t a t o I d 
 
                     a n d       r s o g . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
                     a n d       m o v . m o v g e s t _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                     a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , m o v . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( m o v . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , t s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( t s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) , 
 
                     s o g   a s 
 
                     ( 
 
                     s e l e c t   s o g . s o g g e t t o _ i d ,   s o g . s o g g e t t o _ c o d e ,   s o g . s o g g e t t o _ d e s c 
 
                     f r o m   s i a c _ t _ s o g g e t t o   s o g 
 
                     w h e r e   s o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) 
 
                     s e l e c t   p a g o p a . p a g o p a _ r i c _ d o c _ i d , 
 
                                   ( c a s e   w h e n   s 1 . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   s 1 . s o g g e t t o _ i d   e l s e   s 2 . s o g g e t t o _ i d   e n d   )   p a g o p a _ s o g g e t t o _ i d , 
 
                                   p a g o p a . p a g o p a _ r i c _ i d 
 
                     f r o m   p a g o p a   l e f t   j o i n   s o g   s 1   o n   ( p a g o p a . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f = s 1 . s o g g e t t o _ c o d e ) , 
 
                               a c c e r t a m e n t i   j o i n   s o g   s 2   o n   ( a c c e r t a m e n t i . s o g g e t t o _ i d = s 2 . s o g g e t t o _ i d ) 
 
                   )   q u e r y , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e 
 
                   w h e r e   d o c U P D . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 - -                   a n d       d o c U P D . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' N ' 
 
                   a n d       d o c U P D . p a g o p a _ r i c _ i d = Q U E R Y . p a g o p a _ r i c _ i d 
 
                   a n d       Q U E R Y . p a g o p a _ s o g g e t t o _ i d = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o g g e t t o _ i d 
 
                   a n d       e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = d o c U P D . e n t e _ p r o p r i e t a r i o _ i d 
 
                   a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e =   p a g o P a C o d e E r r 
 
                   a n d       d o c U P D . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       d o c U P D . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
 - -   A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T , E L A B O R A T O _ I N _ C O R S O _ S C _ S T , E L A B O R A T O _ I N _ C O R S O _ E R _ S T 
 
 
 
 s e l e c t   * 
 
 f r o m   s i a c _ d _ f i l e _ p a g o p a _ s t a t o   s t a t o 
 
 w h e r e   s t a t o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 
 
 A C Q U I S I T O 
 
 E L A B O R A T O _ I N _ C O R S O 
 
 E L A B O R A T O _ I N _ C O R S O _ S C 
 
 E L A B O R A T O _ I N _ C O R S O _ E R 