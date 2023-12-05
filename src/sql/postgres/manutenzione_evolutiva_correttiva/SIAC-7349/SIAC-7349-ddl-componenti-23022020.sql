/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop table if exists siac_d_bil_elem_det_comp_tipo_imp;


CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_tipo_imp
(
                elem_det_comp_tipo_imp_id SERIAL,
                elem_det_comp_tipo_imp_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_imp_desc VARCHAR(500) NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_imp PRIMARY KEY (elem_det_comp_tipo_imp_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_imp IS 'Impegnabile del Componente in fase di assunzione di nuovi impegni ';  
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_imp.elem_det_comp_tipo_imp_code IS ' Valore ammessi Si, No, Automatica';

SELECT * FROM  fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo_imp', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_imp', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');	

SELECT * FROM fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_imp', 'siac_d_bil_elem_det_comp_tipo_imp_fk_ente_proprietario_id_idx','ente_proprietario_id', null, false);
SELECT * FROM fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_imp', 'siac_d_bil_elem_det_comp_tipo_imp_idx_1','elem_det_comp_tipo_imp_code,validita_inizio, ente_proprietario_id', 'data_cancellazione is null', false);


ALTER TABLE siac.siac_d_bil_elem_det_comp_tipo_imp OWNER TO siac;
 
SELECT * FROM  fnc_dba_add_column_params ( 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_imp_id', 'INTEGER');
SELECT * FROM fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_imp_id_idx','elem_det_comp_tipo_imp_id', null, false);
SELECT * FROM  fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_elem_det_comp_tipo_imp', 'elem_det_comp_tipo_imp_id', 'siac_d_bil_elem_det_comp_tipo_imp', 'elem_det_comp_tipo_imp_id');
 

ALTER TABLE siac_d_bil_elem_det_comp_tipo  ALTER COLUMN elem_det_comp_tipo_gest_aut DROP NOT NULL;
  
  
  
 