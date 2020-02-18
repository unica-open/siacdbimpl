/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_d_bil_elem_categoria(elem_cat_code, elem_cat_desc, validita_inizio, ente_proprietario_id, login_operazione) 
SELECT 
	'BDG', 
	'Budget Fondini', 
	now(),
	ente.ente_proprietario_id, 
	'admin'
from siac.siac_t_ente_proprietario ente
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_bil_elem_categoria dbec
	WHERE dbec.ente_proprietario_id = ente.ente_proprietario_id
	AND dbec.elem_cat_code = 'BDG'
);


INSERT INTO siac.siac_r_bil_elem_tipo_categoria(elem_tipo_id, validita_inizio, elem_cat_id, ente_proprietario_id, login_operazione)
SELECT 
	(SELECT elem_tipo_id 
	 FROM siac.siac_d_bil_elem_tipo 
	 WHERE elem_tipo_code=TRIM('CAP-UG') 
	 AND ente_proprietario_id=ente.ente_proprietario_id
	), 
	now(),
	(SELECT elem_cat_id
	 FROM siac.siac_d_bil_elem_categoria
	 WHERE elem_cat_code=TRIM('BDG') 
	 AND ente_proprietario_id=ente.ente_proprietario_id
	),
	ente.ente_proprietario_id, 
	'admin'
from siac.siac_t_ente_proprietario ente
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_r_bil_elem_tipo_categoria dbec
	WHERE dbec.ente_proprietario_id = ente.ente_proprietario_id
	AND dbec.elem_tipo_id=(SELECT elem_tipo_id 
	 FROM siac.siac_d_bil_elem_tipo 
	 WHERE elem_tipo_code=TRIM('CAP-UG')  AND ente_proprietario_id=ente.ente_proprietario_id )
	AND dbec.elem_cat_id=(SELECT elem_cat_id
	 FROM siac.siac_d_bil_elem_categoria
	 WHERE elem_cat_code=TRIM('BDG')  AND ente_proprietario_id=ente.ente_proprietario_id )
	
);

INSERT INTO siac.siac_r_bil_elem_tipo_categoria(elem_tipo_id, validita_inizio, elem_cat_id, ente_proprietario_id, login_operazione)
SELECT 
	(SELECT elem_tipo_id 
	 FROM siac.siac_d_bil_elem_tipo 
	 WHERE elem_tipo_code=TRIM('CAP-UP') 
	 AND ente_proprietario_id=ente.ente_proprietario_id
	), 
	now(),
	(SELECT elem_cat_id
	 FROM siac.siac_d_bil_elem_categoria
	 WHERE elem_cat_code=TRIM('BDG') 
	 AND ente_proprietario_id=ente.ente_proprietario_id
	),
	ente.ente_proprietario_id, 
	'admin'
from siac.siac_t_ente_proprietario ente
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_r_bil_elem_tipo_categoria dbec
	WHERE dbec.ente_proprietario_id = ente.ente_proprietario_id
	AND dbec.elem_tipo_id=(SELECT elem_tipo_id 
	 FROM siac.siac_d_bil_elem_tipo 
	 WHERE elem_tipo_code=TRIM('CAP-UP')  AND ente_proprietario_id=ente.ente_proprietario_id )
	AND dbec.elem_cat_id=(SELECT elem_cat_id
	 FROM siac.siac_d_bil_elem_categoria
	 WHERE elem_cat_code=TRIM('BDG')  AND ente_proprietario_id=ente.ente_proprietario_id )
	
)
		
