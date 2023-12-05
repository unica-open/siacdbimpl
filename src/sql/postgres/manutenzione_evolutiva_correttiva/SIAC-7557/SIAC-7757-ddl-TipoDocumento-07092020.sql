/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
 
--NUOVE COLONNE ALLA TABELLA TIPO DOCUMENTO FEL: SIRFEL_D_TIPO_DOCUMENTO
SELECT * FROM  fnc_dba_add_column_params ( 'sirfel_d_tipo_documento', 'doc_tipo_e_id', 'integer');
SELECT * FROM  fnc_dba_add_column_params ( 'sirfel_d_tipo_documento', 'doc_tipo_s_id', 'integer');

COMMENT ON COLUMN siac.sirfel_d_tipo_documento.doc_tipo_e_id IS 'Tipo Documento CONTABILIA entrata';
COMMENT ON COLUMN siac.sirfel_d_tipo_documento.doc_tipo_s_id IS 'Tipo Documento CONTABILIA spesa';

SELECT * FROM  fnc_dba_add_fk_constraint('sirfel_d_tipo_documento', 'siac_d_doc_tipo_e_sirfel_d_tipo_documento', 'doc_tipo_e_id', 'siac_d_doc_tipo', 'doc_tipo_id');
SELECT * FROM  fnc_dba_add_fk_constraint('sirfel_d_tipo_documento', 'siac_d_doc_tipo_s_sirfel_d_tipo_documento', 'doc_tipo_s_id', 'siac_d_doc_tipo', 'doc_tipo_id');


--controllare se sarà necessario aggiunre i controlli di unique