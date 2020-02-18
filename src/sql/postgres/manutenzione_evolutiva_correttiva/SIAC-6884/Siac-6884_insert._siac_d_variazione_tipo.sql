/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
INSERT INTO siac.siac_d_variazione_tipo (variazione_tipo_id, variazione_tipo_code, variazione_tipo_desc, validita_inizio, validita_fine, ente_proprietario_id, data_creazione, data_modifica, data_cancellazione, login_operazione)
select  nextval('siac.siac_d_variazione_tipo_variazione_tipo_id_seq')  
,'VD'
,'Variazione Decentrata'
, '2019-11-07 00:00:00'
, null
,ente.ente_proprietario_id
,'2019-11-07 00:00:00'
,'2019-11-07 00:00:00'
,null
,'SIAC-6884'
from siac.siac_t_ente_proprietario ente
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_variazione_tipo dbt
	WHERE dbt.ente_proprietario_id = ente.ente_proprietario_id
	AND dbt.variazione_tipo_id=(SELECT variazione_tipo_id 
	 FROM siac.siac_d_variazione_tipo 
	 WHERE variazione_tipo_code=TRIM('VD')  AND ente_proprietario_id=ente.ente_proprietario_id )
);