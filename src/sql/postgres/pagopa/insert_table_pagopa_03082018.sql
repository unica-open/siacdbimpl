/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--

/*ACQUISITO	ACQUISITO IN ATTESA DI ELABORAZIONE
ELBORATO_IN_CORSO ELABORIAZIONE IN CORSO - FLUSSI IN FASE DI ELABORAZIONE
RIFIUTATO	RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE
ELABORATO_OK	ELABORATO CON ESITO POSITIVO
ELABORATO_ERRATO	ELABORATO CON ESITO ERRATO
ELABORATO_SCARTATO	ELABORATO CON ESITO ERRATO - RIELABORABILE
ANNULLATO	ANNULLATO*/

 
 
insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ACQUISITO',
 'ACQUISITO IN ATTESA DI ELABORAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ACQUISITO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'RIFIUTATO',
 'RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='RIFIUTATO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO',
 'ELABORAZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_ER',
 'ELABORAZIONE IN CORSO CON ESITI ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO_ER');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_SC',
 'ELABORAZIONE IN CORSO CON ESITI SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO_SC');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_OK',
 'ELABORATO CON ESITO POSITIVO - DOCUMENTI EMESSI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_OK');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_KO',
 'ELABORATO CON ESITO ERRATO -  DOCUMENTI EMESSI - PRESENZA ERRORI - SCARTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_KO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_ERRATO',
 'ELABORATO CON ESITO ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_ERRATO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_SCARTATO',
 'ELABORATO CON ESITO SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_SCARTATO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ANNULLATO',
 'ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ANNULLATO');

-- siac_d_file_pagopa_stato


 
insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'TRASMESSO',
 'TRASMESSO DA EPAY',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='TRASMESSO');



insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'IN_ACQUISIZIONE',
 'ACQUISIZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='IN_ACQUISIZIONE');


 
 
 insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ACQUISITO',
 'ACQUISITO IN ATTESA DI ELABORAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ACQUISITO');
 
 
insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'RIFIUTATO',
 'RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='RIFIUTATO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO',
 'ELABORAZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_ER',
 'ELABORAZIONE IN CORSO CON ESITI ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO_ER');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_SC',
 'ELABORAZIONE IN CORSO CON ESITI SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO_SC');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_OK',
 'ELABORATO CON ESITO POSITIVO -  DOCUMENTI EMESSI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_OK');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_KO',
 'ELABORATO CON ESITO ERRATO -  DOCUMENTI EMESSI - PRESENZA ERRORI - SCARTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_KO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_ERRATO',
 'ELABORATO CON ESITO ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_ERRATO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_SCARTATO',
 'ELABORATO CON ESITO SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_SCARTATO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ANNULLATO',
 'ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ANNULLATO');


/*1	ANNULLATO
2	SCARTATO
3	ERRORE GENERICO
4	FILE NON ESISTENTE O STATO NON RICHIESTO
5	FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
6	DATI DI RICONCILIAZIONE NON PRESENTI
7	DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
8	DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
9	DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
10	DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
11	DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
12	DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
13	DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
14	DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
15	DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
16	DATI DI RICONCILIAZIONE SENZA IMPORTO
17	ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
18	ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
19	ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
20	DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
21	ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
22	DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
23	DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
24	TIPO DOCUMENTO IPA NON ESISTENTE*/


select *    from pagopa_d_riconciliazione_errore
where ente_proprietario_id=2
 --- pagopa_d_riconciliazione_errore

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '1','ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='1');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '2','SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='2');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '3','ERRORE GENERICO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='3');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '4','FILE NON ESISTENTE O STATO NON RICHIESTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='4');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '5','FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='5');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '6','DATI DI RICONCILIAZIONE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='6');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '7','DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='7');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '8','DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='8');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '9','DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='9');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '10','DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='10');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '11','DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='11');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '12','DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='12');



insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '13','DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='13');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '14','DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='14');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '15','DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='15');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '16','DATI DI RICONCILIAZIONE SENZA IMPORTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='16');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '17','ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='17');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '18','ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='18');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '19','ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='19');



insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '20','DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='20');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '21','ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='21');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '22','DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='22');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '23','DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='23');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '24','TIPO DOCUMENTO IPA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='24');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '25','BOLLO ESENTE NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='25');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '26','ERRORE IN LETTURA ID. STATO DOCUMENTO VALIDO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='26');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '27','ERRORE IN LETTURA ID. TIPO CDC-CDR',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='27');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '28','IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='28');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '29','IDENTIFICATIVI VARI INESISTENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='29');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '30','ERRORE IN FASE DI INSERIMENTO DOCUMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='30');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '31','ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='31');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '32','ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='32');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '33','DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='33');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '34','DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='34');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '35','DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='35');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '36','DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='36');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '37','ERRORE IN LETTURA PROGRESSIVI DOCUMENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='37');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '38','DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='38');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '39','PROVVISORIO DI CASSA REGOLARIZZATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='39');

--- siac_d_doc_tipo
select  *
from siac_d_doc_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code='IPA'

select  r.*
from siac_d_doc_tipo tipo,siac_r_doc_tipo_attr r
where tipo.ente_proprietario_id=2
and   tipo.doc_tipo_code='DSI'
and   r.doc_tipo_id=tipo.doc_tipo_id

insert into siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  doc_gruppo_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select 'IPA',
       'INCASSI PAGOPA',
       tipo.doc_fam_tipo_id,
       tipo.doc_gruppo_tipo_id,
       now(),
       'admin_pagoPA',
       tipo.ente_proprietario_id
from siac_d_doc_tipo tipo,siac_t_ente_proprietario ente
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.doc_tipo_code='DSI'
and   not exists
(select 1 from siac_d_doc_tipo tipo1 where tipo1.ente_proprietario_id=ente.ente_proprietario_id and tipo1.doc_tipo_code='IPA');

insert into siac_r_doc_tipo_attr
(
  doc_tipo_id,
  attr_id,
  tabella_id,
  boolean,
  percentuale,
  testo,
  numerico,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select tipoipa.doc_tipo_id,
       r.attr_id,
       r.tabella_id,
       r.boolean,
       r.percentuale,
       r.testo,
       r.numerico,
       now(),
       'admin_pagoPA',
       tipoipa.ente_proprietario_id
from siac_r_doc_tipo_attr r, siac_d_doc_tipo tipo,siac_t_ente_proprietario ente,
     siac_d_doc_tipo tipoipa
where tipo.doc_tipo_code='DSI'
and   ente.ente_proprietario_id=tipo.ente_proprietario_id
and   tipoipa.ente_proprietario_id=ente.ente_proprietario_id
and   tipoipa.doc_tipo_code='IPA'
and   r.doc_tipo_id=tipo.doc_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(
 select 1 from siac_r_doc_tipo_attr r1
 where r1.doc_tipo_id=tipoipa.doc_tipo_id
 and   r1.attr_id=r.attr_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);