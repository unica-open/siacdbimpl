/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/* ---------------------------------------------------------------------- */
/* Add table "siac.siac_r_ruolo_op_bil"                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE siac.siac_r_ruolo_op_bil (
    ruolo_op_bil_id SERIAL  NOT NULL,
    ruolo_op_id INTEGER  NOT NULL,
    bil_id INTEGER  NOT NULL,
    validita_inizio TIMESTAMP  NOT NULL,
    validita_fine TIMESTAMP,
    ente_proprietario_id INTEGER  NOT NULL,
    data_creazione TIMESTAMP DEFAULT now()  NOT NULL,
    data_modifica TIMESTAMP DEFAULT now()  NOT NULL,
    data_cancellazione TIMESTAMP,
    login_operazione CHARACTER VARYING(200)  NOT NULL,
    CONSTRAINT PK_siac_r_ruolo_op_bil PRIMARY KEY (ruolo_op_bil_id)
);

CREATE UNIQUE INDEX IDX_siac_r_ruolo_op_bil_1 ON siac.siac_r_ruolo_op_bil (ruolo_op_id,bil_id,validita_inizio,ente_proprietario_id) where data_cancellazione IS NULL;

/* ---------------------------------------------------------------------- */
/* Add foreign key constraints                                            */
/* ---------------------------------------------------------------------- */

ALTER TABLE siac.siac_r_ruolo_op_bil ADD CONSTRAINT siac_d_ruolo_op_siac_r_ruolo_op_bil 
    FOREIGN KEY (ruolo_op_id) REFERENCES siac.siac_d_ruolo_op (ruolo_op_id);

ALTER TABLE siac.siac_r_ruolo_op_bil ADD CONSTRAINT siac_t_bil_siac_r_ruolo_op_bil 
    FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil (bil_id);
