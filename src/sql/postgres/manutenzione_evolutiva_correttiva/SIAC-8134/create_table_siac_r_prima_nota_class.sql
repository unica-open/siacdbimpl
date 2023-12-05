/*
 * SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
 * SPDX-License-Identifier: EUPL-1.2
 */
DROP TABLE IF EXISTS siac.siac_r_prima_nota_class;

CREATE TABLE IF NOT EXISTS siac.siac_r_prima_nota_class (
    pnota_classif_id SERIAL NOT NULL,
    pnota_id INTEGER NOT NULL,
    classif_id INTEGER NOT NULL,
    validita_inizio TIMESTAMP NOT NULL,
    validita_fine TIMESTAMP NULL,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP NOT NULL DEFAULT NOW(),
    data_modifica TIMESTAMP NOT NULL DEFAULT NOW(),
    data_cancellazione TIMESTAMP NULL,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT pk_siac_r_prima_nota_class PRIMARY KEY (pnota_classif_id),
	CONSTRAINT siac_t_prima_nota_siac_r_prima_nota_class FOREIGN KEY (pnota_id) REFERENCES siac.siac_t_prima_nota(pnota_id),
	CONSTRAINT siac_t_class_siac_r_prima_nota_class FOREIGN KEY (classif_id) REFERENCES siac.siac_t_class(classif_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_prima_nota_class FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

CREATE UNIQUE INDEX idx_siac_r_prima_nota_class_1 ON siac.siac_r_prima_nota_class USING btree (pnota_id, classif_id, validita_inizio, ente_proprietario_id) WHERE (data_cancellazione IS NULL);
CREATE INDEX siac_r_prima_nota_class_fk_pnota_id_idx ON siac.siac_r_prima_nota_class USING btree (pnota_id);
CREATE INDEX siac_r_prima_nota_class_fk_classif_id_idx ON siac.siac_r_prima_nota_class USING btree (classif_id);
CREATE INDEX siac_r_prima_nota_class_fk_ente_proprietario_id_idx ON siac.siac_r_prima_nota_class USING btree (ente_proprietario_id);

-- se lanciato con siac_rw
GRANT ALL PRIVILEGES ON TABLE siac.siac_r_prima_nota_class TO siac;

--CREATE SEQUENCE siac_r_prima_nota_class_pnota_classif_id_seq START 1 INCREMENT 1 MINVALUE 1 OWNED BY siac_r_prima_nota_class.pnota_classif_id;

GRANT USAGE, SELECT ON SEQUENCE siac_r_prima_nota_class_pnota_classif_id_seq TO siac;