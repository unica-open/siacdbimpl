/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-7903 02.12.2020 Sofia
/*si richiede che la dicitura "cig da definire in fase di liquidazione"
sia sostituita con "cig da specificare in fase di liquidazione" in quanto alcuni utenti
non hanno capito che trattandosi di impegni plurimi dovevano comunque avere il CIG e
l'avrebbero specificato per i vari soggetti liquidati.
Invece la dicitura "da definire" trae in inganno*/

select *
from siac_d_siope_assenza_motivazione d
where d.ente_proprietario_id=2
and   d.siope_assenza_motivazione_code='CL'
and   d.siope_assenza_motivazione_desc='Cig da definire in fase di liquidazione'
and   d.data_cancellazione is null

begin;
update siac_d_siope_assenza_motivazione d
set    siope_assenza_motivazione_desc='cig da specificare in fase di liquidazione',
       data_modifica=now(),
       login_operazione=d.login_operazione||'-SIAC-7903'
where d.ente_proprietario_id in (2,3,4,5,10,14,16)
and   d.siope_assenza_motivazione_code='CL'
and   d.siope_assenza_motivazione_desc='Cig da definire in fase di liquidazione'
and   d.data_cancellazione is null


       