/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into fase_bil_d_elaborazione_tipo
(
  fase_bil_elab_tipo_code,
  fase_bil_elab_tipo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select 'APE_GEST_REIMP_VINC',
       'APERTURA BILANCIO : GESTIONE REIMPUTAZIONE VINCOLI IMPEGNI-ACCERTAMENTI',
       now(),
       'admin',
       e.ente_proprietario_id
from siac_t_ente_proprietario e
where not exists
(
select 1
from fase_bil_d_elaborazione_tipo tipo
where tipo.ente_proprietario_id=e.ente_proprietario_id
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP_VINC'
);

-- aggiunta del campo fase_bil_elab_coll_id per elaborazione_id collegata
alter table fase_bil_t_elaborazione add
    fase_bil_elab_coll_id integer;

--- aggiunta dei campi attoamm_id   e stato del movimento di origine
alter table fase_bil_t_reimputazione
  add attoamm_id integer,
  add movgest_stato_id integer;
