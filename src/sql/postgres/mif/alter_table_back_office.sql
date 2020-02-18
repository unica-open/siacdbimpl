/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
 18.04.2016 Sofia - rilascio modifiche per flussi da back-office
-- 19.04.2016 Sofia - eseguito in prod-BIL-MULT
alter table siac_t_ente_oil add  ente_oil_genera_xml  boolean default false not null

update siac_t_ente_oil set ente_oil_genera_xml=TRUE
where ente_proprietario_id in (4,5,10,11,13,31,32,14,29)

select e.ente_proprietario_id, e.ente_denominazione , oil.ente_oil_genera_xml
from siac_t_ente_oil oil, siac_t_ente_proprietario e
where e.ente_proprietario_id=oil.ente_proprietario_id
order by e.ente_proprietario_id;



--
alter table  mif_t_ordinativo_entrata add  mif_ord_codice_flusso_oil  varchar(50)  null;
alter table  mif_t_ordinativo_spesa add  mif_ord_codice_flusso_oil  varchar(50)  null;

alter table mif_t_flusso_elaborato add flusso_elab_mif_codice_flusso_oil  varchar(50)  null;


