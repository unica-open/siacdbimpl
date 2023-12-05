 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	
	
insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD16',
'Integrazione fattura reverse charge interno',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD16'
and   tipoDOC.descrizione='Integrazione fattura reverse charge interno'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD17',
'Integrazione/autofattura per acquisto servizi dall''estero',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD17'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto servizi dall''estero'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD18',
'Integrazione per acquisto di beni intracomunitari',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD18'
and   tipoDOC.descrizione='Integrazione per acquisto di beni intracomunitari'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD19',
'Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD19'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD20',
'Autofattura per regolarizzazione e integrazione delle fatture (ex art.6 c.8 d.lgs.471/97 o art.46 c.5 D.L. 331/93',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD20'
and   tipoDOC.descrizione='Autofattura per regolarizzazione e integrazione delle fatture (ex art.6 c.8 d.lgs.471/97 o art.46 c.5 D.L. 331/93'
);

 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	
	
insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD16',
'Integrazione fattura reverse charge interno',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD16'
and   tipoDOC.descrizione='Integrazione fattura reverse charge interno'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD17',
'Integrazione/autofattura per acquisto servizi dall''estero',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD17'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto servizi dall''estero'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD18',
'Integrazione per acquisto di beni intracomunitari',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD18'
and   tipoDOC.descrizione='Integrazione per acquisto di beni intracomunitari'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD19',
'Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD19'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD21',
'Autofattura per splafonamento',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD21'
and   tipoDOC.descrizione='Autofattura per splafonamento'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD22',
'Estrazione benida Deposito IVA',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD22'
and   tipoDOC.descrizione='Estrazione benida Deposito IVA'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD23',
'Estrazione beni da Deposito IVA con versamento dell'' IVA',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD23'
and   tipoDOC.descrizione='Estrazione beni da Deposito IVA con versamento dell'' IVA'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD24',
'Fattura differita di cui all''art.21, comma 4, lett. a)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD24'
and   tipoDOC.descrizione='Fattura differita di cui all''art.21, comma 4, lett. a)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD25',
'Fattura differita di cui all''art.21, comma 4, terzo periodo lett. b)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD25'
and   tipoDOC.descrizione='Fattura differita di cui all''art.21, comma 4, terzo periodo lett. b)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD26',
'Cessione di beni ammortizzabili e per passaggi interni (ex art.36 DPR 633/72)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD26'
and   tipoDOC.descrizione='Cessione di beni ammortizzabili e per passaggi interni (ex art.36 DPR 633/72)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD27',
'Fattura per autoconsumo o per cessioni gratuite senza rivalsa',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD27'
and   tipoDOC.descrizione='Fattura per autoconsumo o per cessioni gratuite senza rivalsa'
);




