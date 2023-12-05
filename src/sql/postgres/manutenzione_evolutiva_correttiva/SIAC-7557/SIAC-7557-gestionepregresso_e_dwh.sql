/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	

CREATE OR REPLACE VIEW siac.siac_v_dwh_datiritenuta_sirfel
 AS
select siac.sirfel_t_fattura.id_fattura, siac.sirfel_t_dati_ritenuta.aliquota, siac.sirfel_t_dati_ritenuta.importo, siac.sirfel_t_dati_ritenuta.tipo
from siac.sirfel_t_dati_ritenuta, siac.sirfel_t_fattura
where siac.sirfel_t_fattura.id_fattura = siac.sirfel_t_dati_ritenuta.id_fattura 
and siac.sirfel_t_fattura.ente_proprietario_id = siac.sirfel_t_dati_ritenuta.ente_proprietario_id
and siac.sirfel_t_dati_ritenuta.data_cancellazione is null;

GRANT SELECT ON siac.siac_v_dwh_datiritenuta_sirfel TO siac_dwh; 

insert into siac.sirfel_t_dati_ritenuta 
(id_ritenuta, id_fattura, ente_proprietario_id, tipo, importo, aliquota, validita_inizio, data_creazione, data_modifica, login_operazione, causale_pagamento)  
select 
nextval('siac.SIRFEL_T_DATI_RITENUTA_NUM_ID_SEQ'), id_fattura, ente_proprietario_id, tipo_ritenuta, importo_ritenuta, aliquota_ritenuta, now(), data_inserimento, now(), 'SIAC-7557', causale_pagamento 
from siac.sirfel_t_fattura where tipo_ritenuta is not null;

drop table if exists siac.sirfel_t_fattura_bck;

create table siac.sirfel_t_fattura_bck as select * from siac.sirfel_t_fattura;

update siac.sirfel_t_fattura 
set tipo_ritenuta = null, aliquota_ritenuta = null, causale_pagamento = null, importo_ritenuta = null
where tipo_ritenuta is not null;
