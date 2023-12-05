/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
----SIAC-5436 inizio
INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-SPE-LimitaDatiFELDec',
'predocumenti entrata - modifica accertamento non ammessa',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacbilapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='FIN_BASE2' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-SPE-LimitaDatiFELDec' 
and z.ente_proprietario_id=a.ente_proprietario_id);


CREATE TABLE IF NOT EXISTS siac.siac_r_pcc_ufficio_codice (
    pccuffcod_id SERIAL  NOT NULL,
    pccuff_id INTEGER  NOT NULL,
    pcccod_id INTEGER  NOT NULL,
    validita_inizio TIMESTAMP  NOT NULL,
    validita_fine TIMESTAMP,
    ente_proprietario_id INTEGER  NOT NULL,
    data_creazione TIMESTAMP DEFAULT now()  NOT NULL,
    data_modifica TIMESTAMP DEFAULT now()  NOT NULL,
    data_cancellazione TIMESTAMP,
    login_operazione CHARACTER VARYING(200)  NOT NULL
);

DROP INDEX IF EXISTS IDX_siac_r_pcc_ufficio_codice_1;
CREATE UNIQUE INDEX IDX_siac_r_pcc_ufficio_codice_1 ON siac.siac_r_pcc_ufficio_codice (pccuff_id,pcccod_id,validita_inizio,ente_proprietario_id) where data_cancellazione IS NULL;

/* ---------------------------------------------------------------------- */
/* Add foreign key constraints                                            */
/* ---------------------------------------------------------------------- */

ALTER TABLE siac.siac_r_pcc_ufficio_codice DROP CONSTRAINT IF EXISTS siac_d_pcc_codice_siac_r_pcc_ufficio_codice;
ALTER TABLE siac.siac_r_pcc_ufficio_codice DROP CONSTRAINT IF EXISTS siac_d_pcc_ufficio_siac_r_pcc_ufficio_codice;
ALTER TABLE siac.siac_r_pcc_ufficio_codice DROP CONSTRAINT IF EXISTS siac_t_ente_proprietario_siac_r_pcc_ufficio_codice;
ALTER TABLE siac.siac_r_pcc_ufficio_codice DROP CONSTRAINT IF EXISTS PK_siac_r_pcc_ufficio_codice;

ALTER TABLE siac.siac_r_pcc_ufficio_codice ADD CONSTRAINT PK_siac_r_pcc_ufficio_codice PRIMARY KEY (pccuffcod_id);

ALTER TABLE siac.siac_r_pcc_ufficio_codice ADD CONSTRAINT siac_d_pcc_codice_siac_r_pcc_ufficio_codice 
    FOREIGN KEY (pcccod_id) REFERENCES siac.siac_d_pcc_codice (pcccod_id);

ALTER TABLE siac.siac_r_pcc_ufficio_codice ADD CONSTRAINT siac_d_pcc_ufficio_siac_r_pcc_ufficio_codice 
    FOREIGN KEY (pccuff_id) REFERENCES siac.siac_d_pcc_ufficio (pccuff_id);


ALTER TABLE siac.siac_r_pcc_ufficio_codice ADD CONSTRAINT siac_t_ente_proprietario_siac_r_pcc_ufficio_codice 
    FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario (ente_proprietario_id)
----SIAC-5436 fine
