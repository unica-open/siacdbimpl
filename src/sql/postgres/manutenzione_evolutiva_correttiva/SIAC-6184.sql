/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

INSERT INTO siac_d_accredito_tipo (
  accredito_tipo_code, 
  accredito_tipo_desc, 
  accredito_priorita,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
) 
SELECT  
  x.c, 
  x.d, 
  at.accredito_priorita,
  now(),
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id
FROM siac_d_accredito_tipo at, 
  (SELECT 'CPT' c, 'Cessione presso terzi' d UNION 
   SELECT 'CSIG' c, 'Cessione incasso generica' d) x
WHERE at.accredito_tipo_code='PI';

 

 
INSERT INTO siac_d_relaz_tipo (
  relaz_tipo_code,
  relaz_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) 
SELECT 
  x.c, 
  x.d,
  now(),
  ente_proprietario_id,
  login_operazione
FROM siac_d_relaz_tipo rt,
  (SELECT 'CPT' c, 'Cessione presso terzi' d UNION 
   SELECT 'CSIG' c, 'Cessione incasso generica' d) x
WHERE rt.relaz_tipo_code='PI';

