/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
begin;
-- macro componente
-- Fresco, Avanzo, FPV, Da attribuire
insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Fresco',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='01'
and   tipo.elem_det_comp_macro_tipo_desc='Fresco'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'FPV',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='02'
and   tipo.elem_det_comp_macro_tipo_desc='FPV'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Avanzo',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='03'
and   tipo.elem_det_comp_macro_tipo_desc='Avanzo'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'Da attribuire',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='04'
and   tipo.elem_det_comp_macro_tipo_desc='Da attribuire'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- sotto componente FPV
-- Programmato non impegnato
-- Cumulato
-- Applicato
insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Programmato non impegnato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='01'
and   tipo.elem_det_comp_sotto_tipo_desc='Programmato non impegnato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Cumulato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='02'
and   tipo.elem_det_comp_sotto_tipo_desc='Cumulato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Applicato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='03'
and   tipo.elem_det_comp_sotto_tipo_desc='Applicato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- ambito componente Fresco
-- Autonomo
-- Vincolato
-- Da definire
insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Autonomo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='01'
and   tipo.elem_det_comp_tipo_ambito_desc='Autonomo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Vincolato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='02'
and   tipo.elem_det_comp_tipo_ambito_desc='Vincolato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Da definire',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='03'
and   tipo.elem_det_comp_tipo_ambito_desc='Da definire'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- Fonte componente
-- FPV
--  Fresco / Avanzo
-- Avanzo
--  Avanzo/Reiscrizione Perenti
insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '01',
    'Fresco',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='01'
and   tipo.elem_det_comp_tipo_fonte_desc='Fresco'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '02',
    'Avanzo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='02'
and   tipo.elem_det_comp_tipo_fonte_desc='Avanzo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '03',
    'Avanzo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='03'
and   macro.elem_det_comp_macro_tipo_desc='Avanzo'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='03'
and   tipo.elem_det_comp_tipo_fonte_desc='Avanzo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '04',
    'Reiscrizione Perenti',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='03'
and   macro.elem_det_comp_macro_tipo_desc='Avanzo'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='04'
and   tipo.elem_det_comp_tipo_fonte_desc='Reiscrizione Perenti'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- Momento per FPV
-- Gestione/ROR/ Bilancio previsione
insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Bilancio previsione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='01'
and   tipo.elem_det_comp_tipo_fase_desc='Bilancio previsione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Gestione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='02'
and   tipo.elem_det_comp_tipo_fase_desc='Gestione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'ROR effettivo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='03'
and   tipo.elem_det_comp_tipo_fase_desc='ROR effettivo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'ROR previsione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='04'
and   tipo.elem_det_comp_tipo_fase_desc='ROR previsione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

--- Default
insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Si',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='01'
and   tipo.elem_det_comp_tipo_def_desc='Si'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'No',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='02'
and   tipo.elem_det_comp_tipo_def_desc='No'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Solo Previsione',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='03'
and   tipo.elem_det_comp_tipo_def_desc='Solo Previsione'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'Solo Gestione',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='04'
and   tipo.elem_det_comp_tipo_def_desc='Solo Gestione'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_stato (elem_det_comp_tipo_stato_code, elem_det_comp_tipo_stato_desc, validita_inizio, login_operazione, ente_proprietario_id)
select tmp.code, tmp.descr, now(), 'SIAC-6881', ente.ente_proprietario_id
from siac_t_ente_proprietario ente
cross join (values
    ('V', 'Valido'),
    ('A', 'Annullato')
) as tmp(code, descr)
where not exists (
    select 1
    from siac_d_bil_elem_det_comp_tipo_stato stato
    where stato.ente_proprietario_id = ente.ente_proprietario_id
    and stato.elem_det_comp_tipo_stato_code = tmp.code
    and stato.data_cancellazione is null
    and stato.validita_fine is null
);