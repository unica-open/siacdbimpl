/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE VIEW siac.siac_v_dwh_anagrafica_classi_sog (
    ana_classe_code,
    ana_classe_desc,
    ente_proprietario_id,
    validita_inizio,
    validita_fine)
AS
---------------ANAGRAFICA CLASSI DI SOGGETTO
select a.soggetto_classe_code as ana_classe_code, 
a.soggetto_classe_desc as ana_classe_desc, a.ente_proprietario_id ,
a.validita_inizio, a.validita_fine
from siac_d_soggetto_classe a
where a.data_cancellazione is null
;