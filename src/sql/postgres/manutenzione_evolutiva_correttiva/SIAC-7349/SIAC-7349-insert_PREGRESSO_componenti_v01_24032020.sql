/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--- Valorizzazione pregresso impegnabile
--Un esempio della valorizzazione di tale attributo per le componenti esistenti a sistema e' la seguente:
--Componente	Impegnabile
--Fresco		Si   => OK 
--FPV-A-ROR	    Auto => OK
--FPV-A-GE   	Auto => OK
--FPV-C	        No   => OK
--Avanzo	    Si   => OK
--Da attribuire	No   => OK

UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='Si')
	WHERE  elem_det_comp_macro_tipo_id IN ( SELECT elem_det_comp_macro_tipo_id FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc in ('Fresco','Avanzo') );

 UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='No')
	WHERE  elem_det_comp_macro_tipo_id = ( SELECT elem_det_comp_macro_tipo_id 	FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc ='Da attribuire');


UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='No')
	WHERE  elem_det_comp_macro_tipo_id = ( SELECT elem_det_comp_macro_tipo_id FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc ='FPV')
	AND  elem_det_comp_sotto_tipo_id = ( SELECT elem_det_comp_sotto_tipo_id FROM siac.siac_d_bil_elem_det_comp_sotto_tipo	where elem_det_comp_sotto_tipo_desc ='Cumulato' );


UPDATE siac.siac_d_bil_elem_det_comp_tipo
   SET  elem_det_comp_tipo_imp_id= (SELECT elem_det_comp_tipo_imp_id FROM siac.siac_d_bil_elem_det_comp_tipo_imp where elem_det_comp_tipo_imp_desc ='Si')
	WHERE  elem_det_comp_macro_tipo_id = ( SELECT elem_det_comp_macro_tipo_id  FROM siac.siac_d_bil_elem_det_comp_macro_tipo	where elem_det_comp_macro_tipo_desc ='FPV')
	AND  elem_det_comp_sotto_tipo_id =( SELECT elem_det_comp_sotto_tipo_id 	FROM siac.siac_d_bil_elem_det_comp_sotto_tipo	where elem_det_comp_sotto_tipo_desc ='Applicato' )
	AND  elem_det_comp_tipo_fase_id  IN ( SELECT elem_det_comp_tipo_fase_id FROM siac.siac_d_bil_elem_det_comp_tipo_fase	where elem_det_comp_tipo_fase_desc IN ('Gestione','ROR effettivo'));