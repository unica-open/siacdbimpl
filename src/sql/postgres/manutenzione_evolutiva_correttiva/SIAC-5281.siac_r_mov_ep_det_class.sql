/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP TABLE IF EXISTS siac.siac_r_mov_ep_det_class;

CREATE TABLE siac.siac_r_mov_ep_det_class (
	movep_det_classif_id SERIAL,
	movep_det_id         INTEGER NOT NULL,
	classif_id           INTEGER NOT NULL,
	validita_inizio      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine        TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione       TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica        TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione   TIMESTAMP WITHOUT TIME ZONE,
	login_operazione     CHARACTER VARYING(200) NOT NULL,
	
	CONSTRAINT pk_siac_r_mov_ep_det_class PRIMARY KEY (movep_det_classif_id),
	CONSTRAINT siac_t_mov_ep_det_siac_r_mov_ep_det_class FOREIGN KEY (movep_det_id)
		REFERENCES siac.siac_t_mov_ep_det(movep_det_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	CONSTRAINT siac_t_class_siac_r_mov_ep_det_class FOREIGN KEY (classif_id)
		REFERENCES siac.siac_t_class(classif_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	CONSTRAINT siac_t_ente_proprietario_siac_r_mov_ep_det_class FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
);

ALTER TABLE siac.siac_r_mov_ep_det_class OWNER TO siac;