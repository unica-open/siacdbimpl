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
); p a g o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 o r d e r   b y   p a g o . f i l e _ p a g o p a _ i d 
 
 
 
 
 
 
 
 
 
 s e l e c t   a t t r . a t t r _ c o d e ,   r a t t r . b o o l e a n , r a t t r . b i l _ e l e m _ a t t r _ i d 
 
 f r o m   s i a c _ v _ b k o _ a c c e r t a m e n t o _ v a l i d o   a c c , s i a c _ t _ m o v g e s t _ t s   t s , 
 
           s i a c _ r _ m o v g e s t _ t s _ a t t r   r a t t r , s i a c _ t _ a t t r   a t t r 
 
 w h e r e   a c c . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       a c c . a n n o _ b i l a n c i o = 2 0 1 9 
 
 a n d       a c c . m o v g e s t _ a n n o = 2 0 1 9 
 
 a n d       a c c . m o v g e s t _ n u m e r o = 8 1 
 
 a n d       t s . m o v g e s t _ t s _ i d = a c c . m o v g e s t _ t s _ i d 
 
 a n d       r a t t r . m o v g e s t _ t s _ i d = a c c . m o v g e s t _ t s _ i d 
 
 a n d       a t t r . a t t r _ i d = r a t t r . a t t r _ i d 
 
 a n d       r a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r a t t r . v a l i d i t a _ f i n e   i s   n u l l 
 
 - -   1 3 3 7 6 4 0 
 
 
 
 
 
 
 
 
 
 
 
 
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
 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 1 9 7   A N N O B I L A N C I O E L A B = 2 0 1 9 . I N S E R I M E N T O   D O C U M E N T O   P E R   S O G G E T T O = 2 8 4 2 6 8 .   V O C E   T F 1 0 .   S T R U T T U R A   A M M I N I S T R A T I V A     .   A G G I O R N A M E N T O   P A G O P A _ T _ R I C O N C I L I A Z I O N E _ D O C   P E R   S U B D O C _ I D . E R R O R E :         E R R O R E   I N   A G G I O R N A M E N T O . 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 1 9 3   A N N O B I L A N C I O E L A B = 2 0 1 9 .   V E R I F I C A   E S I S T E N Z A   D E T T A G L I   D I   R I C O N C I L I A Z I O N E   D A   E L A B O R A R E .     D A T I   N O N   P R E S E N T I . . 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 1 9 7   A N N O B I L A N C I O E L A B = 2 0 1 9 . I N S E R I M E N T O   D O C U M E N T O   P E R   S O G G E T T O = 2 8 4 2 6 8 .   V O C E   T F 1 0 .   S T R U T T U R A   A M M I N I S T R A T I V A     .   A G G I O R N A M E N T O   P A G O P A _ T _ R I C O N C I L I A Z I O N E _ D O C   P E R   S U B D O C _ I D . E R R O R E :         E R R O R E   I N   A G G I O R N A M E N T O . 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 1 9 8   A N N O B I L A N C I O E L A B = 2 0 1 9 . I N S E R I M E N T O   D O C U M E N T O   P E R   S O G G E T T O = 2 8 4 2 6 8 .   V O C E   T F 1 0 .   S T R U T T U R A   A M M I N I S T R A T I V A     .   A G G I O R N A M E N T O   P A G O P A _ T _ R I C O N C I L I A Z I O N E _ D O C   P E R   S U B D O C _ I D . E R R O R E :         E R R O R E   I N   A G G I O R N A M E N T O . 
 
 E L A B O R A Z I O N E   P A G O P A . T E R M I N E   K O . E L A B O R A Z I O N E   R I N C O N C I L I A Z I O N E   P A G O P A   P E R   I D .   E L A B O R A Z I O N E   F I L E P A G O P A E L A B I D = 2 0 0   A N N O B I L A N C I O E L A B = 2 0 1 9 .   V E R I F I C A   E S I S T E N Z A   D E T T A G L I   D I   R I C O N C I L I A Z I O N E   D A   E L A B O R A R E .     D A T I   N O N   P R E S E N T I . . 
 
 
 
 s e l e c t   r . p a g o p a _ r i c _ f l u s s o _ n u m _ p r o v v i s o r i o ,   r i c . * 
 
 f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   r i c , p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , p a g o p a _ t _ r i c o n c i l i a z i o n e   r 
 
 w h e r e   r i c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 a n d       f l u s s o . p a g o p a _ e l a b _ i d = 2 0 1 
 
 a n d       r . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
 - -   5 8 9 
 
 s e l e c t   *   f r o m   p a g o p a _ b c k _ t _ s u b d o c   b 
 
 w h e r e   b . p a g o p a _ e l a b _ i d = 1 9 3 ; 
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
 w h e r e     f l u s s o . p a g o p a _ e l a b _ i d = 2 0 1 
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
 i n s e r t   i n t o   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e 
 
 ( 
 
 	 p a g o p a _ r i c _ e r r o r e _ c o d e , 
 
         p a g o p a _ r i c _ e r r o r e _ d e s c , 
 
         v a l i d i t a _ i n i z i o , 
 
         l o g i n _ o p e r a z i o n e , 
 
         e n t e _ p r o p r i e t a r i o _ i d 
 
 ) 
 
 s e l e c t   ' 5 1 ' , 
 
               ' D A T I   R I C O N C I L I A Z I O N E   C O N   A C C E R T A M E N T O   P R I V O   D I   S O G G E T T O   O   I N E S I S T E N T E ' , 
 
               n o w ( ) , 
 
               ' S I A C - 6 9 6 3 ' , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 W H E R E   n o t   e x i s t s 
 
 ( s e l e c t   1 
 
   f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e 
 
   w h e r e   e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
   a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e = ' 5 1 ' 
 
   a n d       e r r o r e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
   ) ; 
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
               ' S I A C - 6 9 6 3 ' , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e   ,   s i a c _ d _ a t t r _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a t t r _ t i p o _ c o d e = ' B ' 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   s i a c _ t _ a t t r   a t t r 
 
 w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       a t t r . a t t r _ t i p o _ i d = t i p o . a t t r _ t i p o _ i d 
 
 a n d       a t t r . a t t r _ c o d e = ' f l a g S e n z a N u m e r o ' 
 
 a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 ) ; 
 
 
 
 
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
               ' S I A C - 6 9 6 3 ' , 
 
               a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ t _ a t t r   a t t r ,       s i a c _ d _ d o c _ t i p o   t i p o , s i a c _ d _ d o c _ f a m _ t i p o   f a m 
 
 w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       a t t r . a t t r _ c o d e = ' f l a g S e n z a N u m e r o ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . d o c _ t i p o _ c o d e   i n   ( ' C O R ' , ' F T V ' ) 
 
 a n d       f a m . d o c _ f a m _ t i p o _ i d = t i p o . d o c _ f a m _ t i p o _ i d 
 
 a n d       f a m . d o c _ f a m _ t i p o _ c o d e = ' E ' 
 
 a n d       n o t   e x i s t s 
 
 ( s e l e c t   1 
 
   f r o m     s i a c _ r _ d o c _ t i p o _ a t t r   r 
 
   w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
   a n d       r . d o c _ t i p o _ i d = t i p o . d o c _ t i p o _ i d 
 
   a n d       r . a t t r _ i d = a t t r . a t t r _ i d 
 
   a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 ) ; 